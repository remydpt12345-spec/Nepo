#!/usr/bin/env bash
# Découpe un épisode horizontal (16:9) en clips verticaux 1080x1920
# pour TikTok et YouTube Shorts.
#
# Usage :
#   outils/decoupe.sh <video.mp4> <clips.txt> [dossier_sortie]
#
# clips.txt : une ligne par clip, au format  debut;fin;nom
#   00:01:45;00:02:45;clap-clap-hello
# Les lignes vides et celles qui commencent par # sont ignorées.
#
# Le recadrage garde le centre de l'image : placer Nubi dans le tiers central.
# Nécessite ffmpeg (brew install ffmpeg).

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage : $0 <video.mp4> <clips.txt> [dossier_sortie]" >&2
  exit 1
fi

video="$1"
liste="$2"
sortie="${3:-clips}"

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg introuvable : brew install ffmpeg" >&2; exit 1; }
[ -f "$video" ] || { echo "Vidéo introuvable : $video" >&2; exit 1; }
[ -f "$liste" ] || { echo "Liste de clips introuvable : $liste" >&2; exit 1; }

mkdir -p "$sortie"
base="$(basename "${video%.*}")"
n=0

while IFS=';' read -r debut fin nom || [ -n "${debut:-}" ]; do
  debut="$(echo "${debut:-}" | tr -d '[:space:]')"
  case "$debut" in ''|\#*) continue ;; esac
  fin="$(echo "${fin:-}" | tr -d '[:space:]')"
  nom="$(echo "${nom:-clip}" | tr -d '[:space:]')"
  n=$((n + 1))
  fichier="$sortie/${base}-$(printf '%02d' "$n")-${nom}.mp4"
  echo "→ $fichier ($debut → $fin)"
  ffmpeg -nostdin -loglevel error -y \
    -ss "$debut" -to "$fin" -i "$video" \
    -vf "crop=ih*9/16:ih,scale=1080:1920:flags=lanczos,setsar=1" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
    -c:a aac -b:a 160k -movflags +faststart \
    "$fichier"
done < "$liste"

echo "$n clip(s) créé(s) dans $sortie/"
