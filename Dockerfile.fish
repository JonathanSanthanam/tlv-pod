# syntax=docker/dockerfile:1.7
#
# Ambiente per la VOCE con Fish Audio Drama 3 (fish-speech) su GPU affittata (24/10/2026).
#
# PERCHE' UN'IMMAGINE SEPARATA: Drama 3 vuole il suo torch (2.8.0) e transformers 5.19, diversi da
# /opt/ltx. Installarli sul pod vorrebbe dire gigabyte da PyPI a ~0,65 MB/s (P094): qui li scarica
# GitHub una volta sola. I pesi (42 GB) NON stanno nell'immagine: il pod li scarica da Hugging Face.
#
# Stessa base delle altre immagini: SSH e /start.sh di RunPod gia' pronti.
# cu128 e non cu129: e' il CUDA che i nostri pod RTX PRO 6000 hanno sempre avuto (driver >= 570).
FROM runpod/pytorch:1.1.0-cu1281-torch291-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore \
    HF_HUB_DISABLE_XET=1 \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# le librerie di sistema che chiede il Dockerfile ufficiale di fish-speech (audio e pyaudio)
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg git jq libsox-dev build-essential cmake libasound-dev \
        portaudio19-dev libportaudio2 libportaudiocpp0 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH=/root/.local/bin:$PATH

# ---- fish-speech, a un commit fissato (R20: mai "main") ------------------
#      541566932a = 14/10/2026, quello dell'immagine ufficiale fishaudio/fish-speech:server-cuda.
ARG FISH_COMMIT=541566932abbaebcb0a40e562a1f846738383f38
RUN git clone https://github.com/fishaudio/fish-speech.git /opt/fish \
    && git -C /opt/fish checkout ${FISH_COMMIT}
WORKDIR /opt/fish
RUN uv sync --python 3.12 --extra cu128 && rm -rf /root/.cache/uv

# Il guardiano del pod e sul_pod.sh usano /opt/ltx/bin/python: qui e' il Python di fish-speech
# (ha huggingface_hub per scaricare i pesi). /opt/ltx in questa immagine non esiste altrimenti.
RUN mkdir -p /opt/ltx/bin && ln -s /opt/fish/.venv/bin/python /opt/ltx/bin/python

# ---- verifica IN BUILD: se non importa, fallisce qui, gratis -------------
RUN /opt/ltx/bin/python -c "import torch, transformers, huggingface_hub, soundfile; \
from fish_speech.models.text2semantic.inference import init_model, generate_long, load_codec_model; \
print('torch', torch.__version__, '| cuda', torch.version.cuda, '| transformers', transformers.__version__)" \
 && echo 'import ambiente fish-speech ok'

WORKDIR /workspace
# NIENTE CMD/ENTRYPOINT: si eredita quello di runpod/pytorch (sshd).
