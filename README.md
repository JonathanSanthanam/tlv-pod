# tlv-pod

Immagine Docker per generare video con **LTX-2.5** su GPU affittata (RunPod e simili).

Contiene **solo l'ambiente**: PyTorch, diffusers da git, transformers 5, ffmpeg, rclone.
**Non contiene modelli** — si scaricano da HuggingFace all'avvio, 73 GiB in circa 5 minuti,
molto più veloce di quanto sarebbe scaricarli dentro un'immagine gigante.

## Uso

Su RunPod, come `imageName`:

```
ghcr.io/JonathanSanthanam/tlv-pod:latest
```

Poi sul pod:

```bash
export HF_TOKEN=...
/opt/tlv/prova_ambiente.sh      # verifica scheda, driver e import
/opt/tlv/scarica_modelli.sh     # 41 file, 73 GiB
```

## Perché è fatta così

Misurato il 20-21 agosto 2026 su RunPod:

| | velocità |
|---|---|
| librerie da PyPI | **0,65 MB/s** → 35-40 minuti |
| modelli da HuggingFace | **300+ MB/s** → 73 GiB in meno di 5 minuti |

Una differenza di 460 volte. Quindi: **le librerie stanno dentro l'immagine, i modelli fuori.**

`cu128` è scelto di proposito: gira sia sulle macchine con driver CUDA 12.8 sia su quelle con
13.0 (compatibilità all'indietro NVIDIA), ed è il minimo per le schede Blackwell.

## Licenza
MIT per gli script. I modelli scaricati a runtime hanno le proprie licenze.
