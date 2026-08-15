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
    && wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu resolute/intel-omix/0.3 unified" | \
    tee /etc/apt/sources.list.d/intel-gpu-26.04.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd intel-gsc \
    intel-omix intel-omix-dev \
    && rm -rf /var/lib/apt/lists/*


# Download and extract the latest Intel IPEX-LLM portable build
# Note: Check the intel/ipex-llm GitHub releases for the absolute latest version
RUN wget https://github.com/alyssaholland99/ipex-llm/releases/download/v3.0.0/ollama-ipex-portable.tgz \
    && tar -xvf ollama-ipex-*.tgz \
    && rm ollama-ipex-*.tgz \
    && mv ollama-ipex-portable ollama \
    && cd ollama \
    && rm -f libc.so.6 libstdc++.so.6 libdl.so.2 libm.so.6 libpthread.so.0 libresolv.so.2 libgcc_s.so.1 librt.so.1

# Set environment variables optimized for the B70's 32GB VRAM
ENV PATH="/llm/ollama:$PATH"
ENV OLLAMA_HOST="0.0.0.0"
ENV ONEAPI_DEVICE_SELECTOR="level_zero:0"
ENV OLLAMA_NUM_CTX=16384 

EXPOSE 11434
ENTRYPOINT ["/llm/ollama/start.sh"]
CMD ["serve"]
