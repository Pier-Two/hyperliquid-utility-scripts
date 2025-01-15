#!/bin/bash

previous_date=""
previous_rmp_file=""

while true
do
  echo "Checking for new date or rmp file..."
  newest_date=$(docker exec hyperliquid-node-1 bash -c "ls -t ~/hl/data/periodic_abci_states | head -n 1")
  newest_rmp_file=$(docker exec hyperliquid-node-1 bash -c "ls -t ~/hl/data/periodic_abci_states/$newest_date | grep '.rmp' | head -n 1")

  if [[ -z "$newest_date" || -z "$newest_rmp_file" ]]; then
    echo "No valid date or rmp file found. Sleeping for 5 seconds..."
    sleep 5
    continue
  fi

  if [[ "$newest_date" != "$previous_date" || "$newest_rmp_file" != "$previous_rmp_file" ]]; then
    echo "New folder or rmp file detected. Removing existing files in /tmp..."
    docker exec hyperliquid-node-1 bash -c "rm -rf /tmp/*"
    echo "Running translate-abci-state on ~/hl/data/periodic_abci_states/$newest_date/$newest_rmp_file..."
    docker exec hyperliquid-node-1 bash -c "./hl-node --chain Testnet translate-abci-state ~/hl/data/periodic_abci_states/$newest_date/$newest_rmp_file /tmp/out.json"
    echo "Searching for 'node_ip' in /tmp/out.json and saving results to /tmp/grep_output.txt..."
    docker exec hyperliquid-node-1 bash -c "grep -r -C 5 'node_ip' /tmp/out.json > /tmp/grep_output.txt"
    echo "Copying /tmp/grep_output.txt from container to host machine..."
    docker cp hyperliquid-node-1:/tmp/grep_output.txt ./grep_output.txt
    previous_date="$newest_date"
    previous_rmp_file="$newest_rmp_file"
  else
    echo "No new date or rmp file detected. Will check again soon..."
  fi

  echo "Sleeping for 5 seconds before checking again..."
  sleep 5
done