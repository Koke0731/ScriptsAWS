#!/bin/bash
set -euo pipefail
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
NOMBRE="${NOMBRE:-Curso-PLF}"
LLAVE="${LLAVE:-$HOME/llavesita.pem}"
ACCION="${1:-entrar}"

read -r ID ESTADO < <(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$NOMBRE" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output text | head -n1) || true

if [ -z "${ID:-}" ]; then
  echo "No encontré ninguna instancia con Name=$NOMBRE (región $AWS_DEFAULT_REGION)"
  exit 1
fi

ip_actual() {
  aws ec2 describe-instances --instance-ids "$ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text
}

case "$ACCION" in
  entrar)
    if [ "$ESTADO" = "stopping" ]; then
      aws ec2 wait instance-stopped --instance-ids "$ID"
      ESTADO="stopped"
    fi
    if [ "$ESTADO" = "stopped" ]; then
      echo "Encendiendo $ID..."
      aws ec2 start-instances --instance-ids "$ID" > /dev/null
    fi
    aws ec2 wait instance-running --instance-ids "$ID"
    aws ec2 wait instance-status-ok --instance-ids "$ID"
    IP="$(ip_actual)"
    echo "Conectando a ubuntu@$IP"
    exec ssh -o StrictHostKeyChecking=accept-new -i "$LLAVE" "ubuntu@$IP"
    ;;
  estado)
    echo "$ID  $ESTADO  $(ip_actual)"
    ;;
  apagar)
    aws ec2 stop-instances --instance-ids "$ID" --output table
    ;;
  *)
    echo "Uso: ./nodo.sh [entrar|estado|apagar]"
    exit 1
    ;;
esac
