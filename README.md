# Ollama for Intel Arc GPUs (IPEX-LLM)

Docker image that runs [Ollama](https://ollama.com) on Intel Arc GPUs using [Intel IPEX-LLM](https://github.com/ipex-llm/ipex-llm). Drop-in replacement for the standard Nvidia-based Ollama container — same API on port 11434.

**Supported GPUs:** Intel Xe Graphics, Intel Arc Pro B70, Arc B580, A770, A750, A380, and other supported Arc-series GPUs.

## Install on Unraid

### Via Community Applications (Recommended)

1. Open the **Apps** tab in Unraid
2. Search for **ollama-intel-gpu**
3. Click **Install**
4. Configure the settings:
   - **Model Storage** — where models are saved on disk (default: `/mnt/user/appdata/ollama-intel-gpu`)
   - **Ollama API Port** — default `11434`
   - **GPU Device Selector** — leave as `level_zero:0` unless you have multiple Intel GPUs
5. Click **Apply**

The container will start with `/dev/dri` passed through automatically for GPU access.

### Verify It's Working

Go to the Unraid **Docker** tab, click the container icon, and select **Logs**. You should see:

```text
oneAPI device name: Intel(R) Graphics [0xe212]
discovered 1 Level-Zero memory modules
inference compute  id=0 library=oneapi name="Intel(R) Graphics [0xe212]" total="15.9 GiB"
```

### Pull a Model

Open the Unraid **Docker** tab, click the container icon, select **Console**, then run:

```bash
ollama run llama3.1:8b "Hello!"
```

### Use with Open WebUI

If you're running [Open WebUI](https://github.com/open-webui/open-webui) on Unraid, point it at this container:

- Set **OLLAMA_BASE_URL** in Open WebUI to `http://<UNRAID_IP>:11434`
- The `OLLAMA_ORIGINS` variable is set to `*` by default in the template to allow cross-origin requests

## Install on Linux

### Requirements

- Intel Xe Graphics or Intel Arc GPU (including Arc Pro B70)
- `/dev/dri` device nodes available on the host
- Host kernel must support the GPU; Arc Pro B70 and newer Xe GPUs require the `xe` driver, while older GPUs use `i915`

### Docker Run

```bash
docker run -d \
  --name ollama-intel-gpu \
  --device=/dev/dri \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  spaceinvaderone/ollama-intel-gpu:latest
```

Then pull and run a model:

```bash
docker exec -it ollama-intel-gpu ollama run llama3.1:8b "Hello!"
```

### Verify GPU Detection

```bash
docker logs ollama-intel-gpu
```

Look for `oneAPI device name: Intel(R) Graphics` and `library=oneapi` in the output.

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `OLLAMA_HOST` | `0.0.0.0:11434` | API listen address |
| `ONEAPI_DEVICE_SELECTOR` | `level_zero:0` | Which Intel GPU to use |
| `OLLAMA_NUM_PARALLEL` | `1` | Parallel requests (keep at 1 for 12 GB cards) |
| `OLLAMA_NUM_CTX` | `4096` | Context window size in tokens |
| `OLLAMA_KEEP_ALIVE` | `10m` | How long to keep model in VRAM (`-1` = forever) |
| `OLLAMA_ORIGINS` | (unset) | Set to `*` for Open WebUI / CORS access |

## Testing the API

```bash
# Health check
curl http://localhost:11434/

# List models
curl http://localhost:11434/api/tags

# Generate
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello!",
  "stream": false
}'
```

## What's Inside

- **Base:** Ubuntu 24.04
- **IPEX-LLM:** v2.3.0 nightly (Ollama portable build optimised for Intel GPUs)
- **Intel GPU drivers:** IGC v2.32.7, Compute Runtime 26.14.37833.4, Level-Zero Loader v1.28.2
