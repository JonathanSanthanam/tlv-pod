#!/usr/bin/env bash
# Verifica veloce PRIMA di scaricare 20 GB di pesi: scheda, memoria, ambiente SenseNova.
# Gemella di prova_ambiente.sh, che fa lo stesso per il video.
set -euo pipefail
nvidia-smi --query-gpu=name,memory.total,power.draw,power.limit,driver_version --format=csv,noheader
/opt/sensenova/.venv/bin/python - <<'PY'
import torch, transformers
print("torch", torch.__version__, "| cuda", torch.version.cuda, "| transformers", transformers.__version__)
assert torch.cuda.is_available(), "GPU non visibile: torch e driver non combaciano"
g = torch.cuda.get_device_properties(0)
print("scheda:", g.name, round(g.total_memory/2**30, 1), "GiB")
# 18B in bf16 sono ~36 GB: sotto le 40 non ci sta in piena precisione
assert g.total_memory/2**30 >= 40, "servono almeno 40 GB per i pesi pieni di SenseNova"
print(">>> ambiente immagini pronto <<<")
PY
