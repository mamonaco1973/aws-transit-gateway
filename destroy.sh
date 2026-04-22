#!/bin/bash
# ==============================================================================
# destroy.sh
# ==============================================================================
# Tears down the transit gateway demo in reverse stage order.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Stage 02 — collect outputs needed to re-supply vars, then destroy
# ------------------------------------------------------------------------------
echo "NOTE: Stage 02 — destroying Transit Gateways and EC2 instances..."

pushd 01-networking > /dev/null
terraform init -reconfigure > /dev/null 2>&1

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

SG1_ID=$(terraform output -raw sg1_id)
SG2_ID=$(terraform output -raw sg2_id)
SG3_ID=$(terraform output -raw sg3_id)
popd > /dev/null

pushd 02-tgw > /dev/null
terraform init -reconfigure > /dev/null 2>&1
terraform destroy -auto-approve \
  -var="vpc1_id=${VPC1_ID}"               \
  -var="vpc2_id=${VPC2_ID}"               \
  -var="vpc3_id=${VPC3_ID}"               \
  -var="subnet1_id=${SUBNET1_ID}"         \
  -var="subnet2_id=${SUBNET2_ID}"         \
  -var="subnet3_id=${SUBNET3_ID}"         \
  -var="rt1_id=${RT1_ID}"                 \
  -var="rt2_id=${RT2_ID}"                 \
  -var="rt3_id=${RT3_ID}"                 \
  -var="public_rt1_id=${PUBLIC_RT1_ID}"   \
  -var="sg1_id=${SG1_ID}"                 \
  -var="sg2_id=${SG2_ID}"                 \
  -var="sg3_id=${SG3_ID}"
popd > /dev/null

# ------------------------------------------------------------------------------
# Stage 01 — destroy VPCs after TGW resources are fully removed
# ------------------------------------------------------------------------------
echo "NOTE: Stage 01 — destroying VPCs and networking..."

pushd 01-networking > /dev/null
terraform destroy -auto-approve
popd > /dev/null

echo "NOTE: All resources destroyed."
