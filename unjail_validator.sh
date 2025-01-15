#!/usr/bin/env bash

VALIDATOR_NAME=""
SIGNING_KEY=""
INTERVAL=10

if ! command -v jq &> /dev/null
then
  echo "jq not found, installing..."
  sudo apt-get update
  sudo apt-get install -y jq
fi

while true
do
  echo "$(date +'%Y-%m-%d %H:%M:%S') Fetching validator info"
  VALIDATOR_INFO=$(curl -s -X POST --header "Content-Type: application/json" \
    --data '{ "type": "validatorSummaries"}' \
    https://api.hyperliquid-testnet.xyz/info | \
    jq '.[] | select(.name == "'${VALIDATOR_NAME}'")')

  IS_JAILED=$(echo "${VALIDATOR_INFO}" | jq -r '.isJailed')
  UNJAILABLE_AFTER=$(echo "${VALIDATOR_INFO}" | jq -r '.unjailableAfter')
  CURRENT_TIME_MS=$(( $(date +%s) * 1000 ))

  echo "$(date +'%Y-%m-%d %H:%M:%S') isJailed: ${IS_JAILED}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') unjailableAfter: ${UNJAILABLE_AFTER}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') currentTimeMs: ${CURRENT_TIME_MS}"

  if [ "${IS_JAILED}" = "true" ]
  then
    if [ "${CURRENT_TIME_MS}" -ge "${UNJAILABLE_AFTER}" ]
    then
      echo "$(date +'%Y-%m-%d %H:%M:%S') Validator is jailed but unjailableAfter has passed, sending unjail action"
      docker exec hyperliquid-node-1 \
        ./hl-node --chain Testnet --key "${SIGNING_KEY}" \
        send-signed-action '{"type": "CSignerAction", "unjailSelf": null}'
      echo "$(date +'%Y-%m-%d %H:%M:%S') Unjail action sent"
    else
      echo "$(date +'%Y-%m-%d %H:%M:%S') Validator is jailed and unjailableAfter not reached, no action taken"
    fi
  else
    echo "$(date +'%Y-%m-%d %H:%M:%S') Validator is not jailed, no action taken"
  fi

  sleep "$INTERVAL"
done