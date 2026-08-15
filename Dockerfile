FROM ubuntu:26.04

WORKDIR /llm

##############################################################################
# from https://dgpu-docs.intel.com/installation-guides/installing-omix.html  #
##############################################################################

# Update your system with the latest Intel GPG public key 
#RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key |
#    gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg

# Installation
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    software-properties-common curl wget clinfo pciutils gnupg \
    && add-apt-repository -y ppa:kobuk-team/intel-graphics \
    && apt-get update && apt-get install -y --no-install-recommends \
    libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd intel-gsc \
    && rm -rf /var/lib/apt/lists/* \
    && wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu 26.04/intel-omix/0.3 unified" | \
    tee /etc/apt/sources.list.d/intel-gpu-26.04.list \
    && apt update \
    && apt install -y intel-omix \
    && apt install -y intel-omix-dev


# Download and extract the latest Intel IPEX-LLM portable build
# Note: Check the intel/ipex-llm GitHub releases for the absolute latest version
RUN wget https://github.com/alyssaholland99/ipex-llm/releases/download/v3.0.0/ollama-ipex-portable.tgz \
    && tar -xvf ollama-ipex-*.tgz \
    && rm ollama-ipex-*.tgz

# Set environment variables optimized for the B70's 32GB VRAM
ENV PATH="/llm/ollama:$PATH"
ENV OLLAMA_HOST="0.0.0.0"
ENV ONEAPI_DEVICE_SELECTOR="level_zero:0"
ENV OLLAMA_NUM_CTX=16384 

EXPOSE 11434
ENTRYPOINT ["/llm/ollama/start-ollama.sh"]
