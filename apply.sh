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
  -var="vpc1_id=${VPC1_ID}"       \
  -var="vpc2_id=${VPC2_ID}"       \
  -var="vpc3_id=${VPC3_ID}"       \
  -var="subnet1_id=${SUBNET1_ID}" \
  -var="subnet2_id=${SUBNET2_ID}" \
  -var="subnet3_id=${SUBNET3_ID}" \
  -var="rt1_id=${RT1_ID}"               \
  -var="rt2_id=${RT2_ID}"               \
  -var="rt3_id=${RT3_ID}"               \
  -var="public_rt1_id=${PUBLIC_RT1_ID}"
popd > /dev/null

# Wait for instances to finish user-data (nginx install + SSM registration)
echo "NOTE: Waiting 120 seconds for instances to initialize..."
sleep 120

# ==============================================================================
# Validation
# ==============================================================================
echo "NOTE: Running post-deployment validation..."
./validate.sh
