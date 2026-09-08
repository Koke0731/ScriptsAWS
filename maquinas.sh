#!/usr/bin/env bash

echo "===== INSTANCIAS EC2 ENCENDIDAS ====="

aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[
    Tags[?Key==`Name`]|[0].Value,
    InstanceId,
    PublicIpAddress,
    PrivateIpAddress,
    Placement.AvailabilityZone
  ]' \
  --output table
