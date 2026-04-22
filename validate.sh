#!/bin/bash
# ==============================================================================
# validate.sh
# ==============================================================================
# Uses SSM to run curl from each EC2 instance to the other two, proving
# cross-region connectivity through the Transit Gateway.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Collect instance IDs and private IPs from Terraform outputs
# ------------------------------------------------------------------------------
pushd 02-tgw > /dev/null
VPC1_ID=$(terraform output -raw vpc1_instance_id)
VPC2_ID=$(terraform output -raw vpc2_instance_id)
VPC3_ID=$(terraform output -raw vpc3_instance_id)

VPC1_IP=$(terraform output -raw vpc1_private_ip)
VPC2_IP=$(terraform output -raw vpc2_private_ip)
VPC3_IP=$(terraform output -raw vpc3_private_ip)
popd > /dev/null

echo "NOTE: VPC1 us-east-1  instance=${VPC1_ID}  ip=${VPC1_IP}"
echo "NOTE: VPC2 us-east-2  instance=${VPC2_ID}  ip=${VPC2_IP}"
echo "NOTE: VPC3 us-west-2  instance=${VPC3_ID}  ip=${VPC3_IP}"

# ------------------------------------------------------------------------------
# Helper: send an SSM shell command, wait for it, and print the output
# ------------------------------------------------------------------------------
run_ssm_check() {
  local region="$1"
  local instance_id="$2"
  local from_label="$3"
  local target_ip="$4"
  local to_label="$5"

  echo ""
  echo "NOTE: [${from_label}] --> [${to_label}]  (curl http://${target_ip})"

  cmd_id=$(aws ssm send-command \
    --region "${region}" \
    --instance-ids "${instance_id}" \
    --document-name "AWS-RunShellScript" \
    --parameters "{\"commands\":[\"curl -s --max-time 5 http://${target_ip}\"]}" \
    --query "Command.CommandId" \
    --output text)

  # Poll until the command reaches a terminal state
  while true; do
    status=$(aws ssm get-command-invocation \
      --region "${region}" \
      --command-id "${cmd_id}" \
      --instance-id "${instance_id}" \
      --query "Status" \
      --output text 2>/dev/null || echo "Pending")
    [[ "$status" == "Success" || "$status" == "Failed" || "$status" == "Cancelled" ]] && break
    sleep 3
  done

  output=$(aws ssm get-command-invocation \
    --region "${region}" \
    --command-id "${cmd_id}" \
    --instance-id "${instance_id}" \
    --query "StandardOutputContent" \
    --output text)

  echo "NOTE: Response: ${output}"
}

# ------------------------------------------------------------------------------
# Run six checks — every instance curls the other two
# ------------------------------------------------------------------------------
run_ssm_check "us-east-1" "${VPC1_ID}" "VPC1 us-east-1" "${VPC2_IP}" "VPC2 us-east-2"
run_ssm_check "us-east-1" "${VPC1_ID}" "VPC1 us-east-1" "${VPC3_IP}" "VPC3 us-west-2"

run_ssm_check "us-east-2" "${VPC2_ID}" "VPC2 us-east-2" "${VPC1_IP}" "VPC1 us-east-1"
run_ssm_check "us-east-2" "${VPC2_ID}" "VPC2 us-east-2" "${VPC3_IP}" "VPC3 us-west-2"

run_ssm_check "us-west-2" "${VPC3_ID}" "VPC3 us-west-2" "${VPC1_IP}" "VPC1 us-east-1"
run_ssm_check "us-west-2" "${VPC3_ID}" "VPC3 us-west-2" "${VPC2_IP}" "VPC2 us-east-2"

echo ""
echo "NOTE: Validation complete."
