#!/usr/bin/env bash
# Regenera operator/koios-operator.yaml desde el código fuente del operador Koios.
# Uso: hack/render-operator.sh <ruta-al-repo-del-operador>
# La imagen no se fija aquí: la fija operator/kustomization.yaml por digest.
set -euo pipefail
src=${1:?ruta al repositorio del operador}
here=$(cd "$(dirname "$0")/.." && pwd)
rev=$(git -C "$src" rev-parse HEAD)
dirty=$(git -C "$src" status --porcelain -- config | wc -l)
[[ $dirty == 0 ]] || { echo "config/ del operador tiene cambios sin commit" >&2; exit 1; }
{
  echo "# Generado por hack/render-operator.sh desde el operador Koios, commit $rev"
  echo "# (kubectl kustomize config/default). No editar a mano."
  kubectl kustomize "$src/config/default"
} > "$here/operator/koios-operator.yaml"
echo "operator/koios-operator.yaml regenerado desde $rev"
