#!/bin/bash

NODE_DATA_DIR="/data1/node-data"

while true
do
  sleep 86400
  find "$NODE_DATA_DIR" -type f -mtime +3 -exec rm -f {} \; 2>&1 > /tmp/deletelist
done