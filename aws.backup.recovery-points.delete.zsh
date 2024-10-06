#!/bin/zsh

export VAULT_NAME="aft-controltower-backup-vault"
export REGION="ap-southeast-2"
PROCESSES=${1-10}

RC_ARNS=$(aws backup list-recovery-points-by-backup-vault \
             --region "${REGION}" \
             --backup-vault-name "${VAULT_NAME}" \
             --query 'RecoveryPoints[].RecoveryPointArn' \
             --output text)

if [ -z "$RC_ARNS" ]; then
  echo "No recovery points found in ${VAULT_NAME}"
  exit 0
fi

echo "${RC_ARNS}" | tr '\t' '\n' | xargs -n 1 -P $PROCESSES -I {} sh -c '
  echo "Deleting backup {} ..."
  aws backup delete-recovery-point --region "${REGION}" --backup-vault-name "${VAULT_NAME}" --recovery-point-arn "{}"
  if [ $? -eq 0 ]; then
    echo "Deleted backup {}"
  else
    echo "Failed to delete backup {}"
  fi
'

# Check that none are remaining...
RC_ARNS=$(aws backup list-recovery-points-by-backup-vault \
             --region "${REGION}" \
             --backup-vault-name "${VAULT_NAME}" \
             --query 'RecoveryPoints[].RecoveryPointArn' \
             --output text)

echo "Deleted all recovery points in ${VAULT_NAME}"
echo "Remaining recovery points:"
echo "${RC_ARNS}"
