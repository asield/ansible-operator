#!/usr/bin/env bash
# Comprueba que todas las kustomizations se construyen y que las imágenes del operador
# están fijadas. Sin clúster.
set -euo pipefail
cd "$(dirname "$0")/.."
for d in operator instance/overlays/internal instance/overlays/ingress \
         instance/overlays/loadbalancer examples/k3d/operator examples/k3d/platform; do
  kubectl kustomize "$d" > /dev/null && echo "OK  $d"
done
img=$(kubectl kustomize operator | grep -E '^\s+image: ' | awk '{print $2}' | sort -u)
echo "imagen del operador: $img"
