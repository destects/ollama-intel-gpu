FROM ubuntu:24.04

WORKDIR /llm

# Install prerequisites and Intel client GPU drivers for Battlemage (Xe2)
RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
    software-properties-common curl wget clinfo pciutils \
    && add-apt-repository -y ppa:kobuk-team/intel-graphics \
    && apt-get update && apt-get install -y --no-install-recommends \
    libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd intel-gsc \
    && rm -rf /var/lib/apt/lists/*

# Download and extract the latest Intel IPEX-LLM portable build
# Note: Check the intel/ipex-llm GitHub releases for the absolute latest version
RUN wget https://github.com/intel/ipex-llm/releases/download/v2.3.0/ollama-ipex-llm-2.3.0-ubuntu.tgz \
    && tar -xvf ollama-ipex-llm-*-ubuntu.tgz \
    && rm ollama-ipex-llm-*-ubuntu.tgz

# Set environment variables optimized for the B70's 32GB VRAM
ENV PATH="/llm/ollama:$PATH"
ENV OLLAMA_HOST="0.0.0.0"
ENV ONEAPI_DEVICE_SELECTOR="level_zero:0"
ENV OLLAMA_NUM_CTX=16384 

EXPOSE 11434
ENTRYPOINT ["/llm/ollama/start-ollama.sh"]
