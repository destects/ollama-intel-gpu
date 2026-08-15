# =============================================================================
# Intel IPEX-LLM Ollama — Docker Image for Intel Arc GPUs
# =============================================================================
# Packages the IPEX-LLM optimised Ollama binary with Intel GPU userspace
# drivers into a minimal Ubuntu 24.04 container. Drop-in replacement for
# the standard Nvidia-based Ollama container.
#
# Tested with: Intel Arc B580 12 GB
# Compatible:  Intel Xe Graphics, Intel Arc Pro B70, and other Arc series
#
# Build:
#   docker build -t ollama-intel-gpu:latest .
#
# Run:
#   docker run -d --name ollama-intel-gpu \
#     --device=/dev/dri \
#     -p 11434:11434 \
#     -v /mnt/user/appdata/ollama:/root/.ollama \
#     ollama-intel-gpu:latest
# =============================================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ---------------------------------------------------------------------------
# Build arguments — override at build time to pin different versions
# ---------------------------------------------------------------------------

# Intel Graphics Compiler (IGC)
ARG IGC_VERSION=v2.32.7
ARG IGC_CORE_DEB=intel-igc-core-2_2.32.7+21184_amd64.deb
ARG IGC_OPENCL_DEB=intel-igc-opencl-2_2.32.7+21184_amd64.deb

# Intel Compute Runtime (Level-Zero GPU driver, OpenCL ICD, gmmlib)
ARG COMPUTE_RT_VERSION=26.14.37833.4
ARG LEVEL_ZERO_GPU_DEB=libze-intel-gpu1_26.14.37833.4-0_amd64.deb
ARG OPENCL_ICD_DEB=intel-opencl-icd_26.14.37833.4-0_amd64.deb
ARG GMMLIB_DEB=libigdgmm12_22.9.0_amd64.deb

# Level-Zero Loader
ARG LEVEL_ZERO_LOADER_VERSION=v1.28.2
ARG LEVEL_ZERO_LOADER_DEB=level-zero_1.28.2+u24.04_amd64.deb

# IPEX-LLM Ollama portable package
ARG IPEXLLM_RELEASE_REPO=alyssaholland99/ipex-llm
ARG IPEXLLM_RELEASE_VERSION=v3.0.0
ARG IPEXLLM_PORTABLE_ZIP=ollama-ipex-portable.tgz
# ---------------------------------------------------------------------------
# Step 1: Install base packages
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install --no-install-recommends -q -y \
        ca-certificates \
        wget \
        ocl-icd-libopencl1 && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Step 2: Install Intel GPU userspace drivers
# ---------------------------------------------------------------------------

RUN mkdir -p /tmp/gpu && cd /tmp/gpu && \
    wget -q https://github.com/oneapi-src/level-zero/releases/download/${LEVEL_ZERO_LOADER_VERSION}/${LEVEL_ZERO_LOADER_DEB} && \
    wget -q https://github.com/intel/intel-graphics-compiler/releases/download/${IGC_VERSION}/${IGC_CORE_DEB} && \
    wget -q https://github.com/intel/intel-graphics-compiler/releases/download/${IGC_VERSION}/${IGC_OPENCL_DEB} && \
    wget -q https://github.com/intel/compute-runtime/releases/download/${COMPUTE_RT_VERSION}/${LEVEL_ZERO_GPU_DEB} && \
    wget -q https://github.com/intel/compute-runtime/releases/download/${COMPUTE_RT_VERSION}/${OPENCL_ICD_DEB} && \
    wget -q https://github.com/intel/compute-runtime/releases/download/${COMPUTE_RT_VERSION}/${GMMLIB_DEB} && \
    dpkg -i *.deb && \
    rm -rf /tmp/gpu

RUN apt-get update && \
    apt-get install --no-install-recommends -q -y software-properties-common && \
    add-apt-repository -y ppa:kobuk-team/intel-graphics && \
    apt-get update && \
    apt-get install --no-install-recommends -q -y \
        libze-intel-gpu1 \
        libze1 \
        intel-metrics-discovery \
        intel-opencl-icd \
        intel-gsc && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Step 3: Download and extract IPEX-LLM Ollama portable package
# ---------------------------------------------------------------------------
RUN wget -q -P /tmp https://github.com/${IPEXLLM_RELEASE_REPO}/releases/download/${IPEXLLM_RELEASE_VERSION}/${IPEXLLM_PORTABLE_ZIP} && \
    tar xf /tmp/${IPEXLLM_PORTABLE_ZIP} --strip-components=1 -C / && \
    rm /tmp/${IPEXLLM_PORTABLE_ZIP}

RUN wget -q -O /tmp/ollama-linux-amd64.tar.zst https://ollama.com/download/ollama-linux-amd64.tar.zst && \
    mkdir /tmp/ollama && \
    tar --zstd -xvf /tmp/ollama-linux-amd64.tar.zst -C /tmp/ollama && \
    mv /tmp/ollama/bin/ollama /

# ---------------------------------------------------------------------------
# Step 4: Configure runtime environment
# ---------------------------------------------------------------------------
# IPEX-LLM / Intel GPU settings (from start-ollama.sh, which we bypass
# because it hardcodes OLLAMA_HOST to 127.0.0.1)
ENV OLLAMA_NUM_GPU=999
ENV ZES_ENABLE_SYSMAN=1
ENV SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
ENV no_proxy=localhost,127.0.0.1

# Ollama settings
ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_NUM_PARALLEL=1
ENV OLLAMA_KEEP_ALIVE=10m

EXPOSE 11434
VOLUME ["/root/.ollama"]

# ---------------------------------------------------------------------------
# Step 5: Entrypoint — run ollama serve directly (bypassing start-ollama.sh
# which hardcodes OLLAMA_HOST=127.0.0.1:11434)
# ---------------------------------------------------------------------------
ENTRYPOINT ["/ollama", "serve"]
