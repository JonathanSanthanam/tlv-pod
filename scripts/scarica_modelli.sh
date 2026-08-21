#!/usr/bin/env bash
# Scarica i pesi di LTX-2.5 dalla lista nominativa: 41 file, 73 GiB.
# NON usare "hf download" senza lista: il repo intero e' 153 GiB e riempie il disco.
set -euo pipefail
: "${HF_TOKEN:?serve HF_TOKEN}"
LISTA=${1:-/opt/tlv/filelist.txt}
echo "[$(date +%H:%M:%S)] scarico $(wc -l < "$LISTA") file (73 GiB)..."
hf download Lightricks/LTX-2.5-Diffusers $(tr '\n' ' ' < "$LISTA") --max-workers 8 > /dev/null
echo "[$(date +%H:%M:%S)] fatto: $(du -sh "$HF_HOME" | cut -f1)"
