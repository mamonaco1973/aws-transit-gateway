#!/bin/bash
# ==============================================================================
# apply.sh
# ==============================================================================
# Deploys the transit gateway demo in two stages:
#   01-networking : VPCs, subnets, IGWs, route tables
#   02-tgw        : Transit Gateways, peering, routes, security groups, EC2 instances
#
# Requires: aws, terraform, jq
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Pre-flight
# ------------------------------------------------------------------------------
echo "NOTE: Running environment validation..."
./check_env.sh

# ==============================================================================
# STAGE 01 — NETWORKING
# ==============================================================================
echo "NOTE: Stage 01 — provisioning VPCs, subnets, and route tables..."

pushd 01-networking > /dev/null
terraform init
terraform apply -auto-approve

VPC1_ID=$(terraform output -raw vpc1_id)
VPC2_ID=$(terraform output -raw vpc2_id)
VPC3_ID=$(terraform output -raw vpc3_id)

SUBNET1_ID=$(terraform output -raw subnet1_id)
SUBNET2_ID=$(terraform output -raw subnet2_id)
SUBNET3_ID=$(terraform output -raw subnet3_id)

RT1_ID=$(terraform output -raw rt1_id)
RT2_ID=$(terraform output -raw rt2_id)
RT3_ID=$(terraform output -raw rt3_id)

PUBLIC_RT1_ID=$(terraform output -raw public_rt1_id)
popd > /dev/null

echo "NOTE: vpc1=${VPC1_ID}  vpc2=${VPC2_ID}  vpc3=${VPC3_ID}"

# ==============================================================================
# STAGE 02 — TRANSIT GATEWAY + EC2
# ==============================================================================
echo "NOTE: Stage 02 — deploying Transit Gateways, peering, and EC2 instances..."

pushd 02-tgw > /dev/null
terraform init
terraform apply -auto-approve \
  -var="vpc1_id=${VPC1_ID}"               \
  -var="vpc2_id=${VPC2_ID}"               \
  -var="vpc3_id=${VPC3_ID}"               \
  -var="subnet1_id=${SUBNET1_ID}"         \
  -var="subnet2_id=${SUBNET2_ID}"         \
  -var="subnet3_id=${SUBNET3_ID}"         \
  -var="rt1_id=${RT1_ID}"                 \
  -var="rt2_id=${RT2_ID}"                 \
  -var="rt3_id=${RT3_ID}"                 \
  -var="public_rt1_id=${PUBLIC_RT1_ID}"

INSTANCE1_ID=$(terraform output -raw vpc1_instance_id)
INSTANCE2_ID=$(terraform output -raw vpc2_instance_id)
INSTANCE3_ID=$(terraform output -raw vpc3_instance_id)
popd > /dev/null

# ==============================================================================
# Wait for SSM readiness
# Poll describe-instance-information until all three instances are Online
# ==============================================================================
wait_for_ssm() {
  local instance_id="$1"
  local region="$2"
  local label="$3"
  local attempts=0

  echo "NOTE: Waiting for SSM on ${label} (${instance_id})..."
  while true; do
    status=$(aws ssm describe-instance-information \
      --filters "Key=InstanceIds,Values=${instance_id}" \
      --region "${region}" \
      --query "InstanceInformationList[0].PingStatus" \
      --output text 2>/dev/null || true)

    if [[ "$status" == "Online" ]]; then
      echo "NOTE: ${label} is SSM-ready."
      return 0
    fi

    attempts=$(( attempts + 1 ))
    if (( attempts >= 36 )); then
      echo "ERROR: ${label} did not become SSM-ready after 6 minutes. Aborting."
      exit 1
    fi

    echo "NOTE: ${label} not ready yet (status=${status:-not registered}), retrying in 10s..."
    sleep 10
  done
}

wait_for_ssm "${INSTANCE1_ID}" "us-east-1" "VPC1 us-east-1"
wait_for_ssm "${INSTANCE2_ID}" "us-east-2" "VPC2 us-east-2"
wait_for_ssm "${INSTANCE3_ID}" "us-west-2" "VPC3 us-west-2"

# ==============================================================================
# Validation
# ==============================================================================
echo "NOTE: Running post-deployment validation..."
./validate.sh
