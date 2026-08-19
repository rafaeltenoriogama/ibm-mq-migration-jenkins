#!/bin/bash
#
# apply_objects.sh
# Aguarda o queue manager PBO11 (container qm1) ficar pronto e aplica
# o dump de criacao de objetos (scripts/create_objects_qm1.mqsc).
#
set -euo pipefail

CONTAINER="qm1"
QMGR="PBO11"
MQSC_FILE="$(dirname "$0")/create_objects_qm1.mqsc"

echo ">> Aguardando queue manager ${QMGR} (container ${CONTAINER}) ficar pronto..."
until docker exec "${CONTAINER}" bash -c "dspmq -m ${QMGR}" 2>/dev/null | grep -q "STATUS(RUNNING)"; do
  echo "   ainda subindo, aguardando 3s..."
  sleep 3
done

echo ">> Queue manager pronto. Aplicando objetos de ${MQSC_FILE}..."
docker exec -i "${CONTAINER}" bash -c "runmqsc ${QMGR}" <"${MQSC_FILE}"

echo ">> Concluido. Objetos criados em ${QMGR}."
