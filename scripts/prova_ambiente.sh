#!/usr/bin/env bash
# Verifica veloce prima di iniziare a spendere: scheda, memoria, import, driver.
set -euo pipefail
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
nvidia-smi | grep -o "CUDA Version: [0-9.]*"
python - <<'PY'
import torch
print("torch", torch.__version__, "| cuda", torch.version.cuda)
assert torch.cuda.is_available(), "GPU non visibile: torch e driver non combaciano"
g = torch.cuda.get_device_properties(0)
print("scheda:", g.name, round(g.total_memory/2**30, 1), "GiB")
assert g.total_memory/2**30 >= 90, "serve una scheda da almeno 96 GB per i pesi pieni"
from diffusers import LTX2ImageToVideoPipeline
print(">>> ambiente pronto <<<")
PY
