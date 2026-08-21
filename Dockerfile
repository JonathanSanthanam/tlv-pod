# syntax=docker/dockerfile:1.7
#
# Ambiente pronto per generare video con LTX-2.5 su GPU affittata.
# Dentro ci vanno le LIBRERIE (35-40 minuti di installazione da PyPI a 0,65 MB/s).
# NON ci vanno i modelli: si scaricano da HuggingFace a 300 MB/s, 73 GiB in 5 minuti.
# Regola: dentro cio' che e' lento da installare, fuori cio' che e' veloce da scaricare.
#
# Base RunPod: SSH e JupyterLab gia' configurati. cu128 gira sia su driver CUDA 12.8
# sia 13.0 (compatibilita' all'indietro NVIDIA) ed e' il minimo per Blackwell (sm_120).
FROM runpod/pytorch:1.1.0-cu1281-torch291-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore \
    HF_HOME=/models/hf \
    HF_HUB_CACHE=/models/hf/hub \
    HF_HUB_DISABLE_XET=1 \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# ---- strumenti di sistema ----------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg git git-lfs aria2 rclone rsync tmux jq unzip bc \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

# ---- le librerie: il blocco che sul pod costa 35-40 minuti -------------
#      diffusers da git: LTX-2.5 non e' ancora in una release ufficiale.
#      transformers>=5 e' obbligatorio: il text encoder e' Gemma4, assente nella 4.x.
RUN uv pip install --system --no-cache \
        "huggingface_hub[cli,hf_transfer]" \
        "transformers>=5" accelerate safetensors sentencepiece protobuf \
        "diffusers @ git+https://github.com/huggingface/diffusers@main" \
        av kernels pillow einops omegaconf \
        imageio imageio-ffmpeg opencv-python-headless \
        soundfile librosa boto3 \
    && rm -rf /root/.cache

COPY scripts/ /opt/tlv/
RUN chmod +x /opt/tlv/*.sh 2>/dev/null || true; mkdir -p /models/hf /workspace/tlv/out

# ---- verifica IN BUILD -------------------------------------------------
#      Se qualcosa non importa, la compilazione fallisce QUI, gratis su GitHub,
#      invece che alle tre di notte su un pod da 2 dollari l'ora.
RUN python -c "import torch, diffusers, transformers; \
print('torch', torch.__version__, '| cuda', torch.version.cuda, \
'| diffusers', diffusers.__version__, '| transformers', transformers.__version__)" \
 && python -c "from diffusers import LTX2Pipeline, LTX2ImageToVideoPipeline, \
LTX2LatentUpsamplePipeline, LTX2VideoTransformer3DModel; print('import LTX ok')"

# NIENTE CMD/ENTRYPOINT: si eredita quello di runpod/pytorch (sshd + jupyter).
# Sovrascriverlo significa perdere l'accesso al pod.
