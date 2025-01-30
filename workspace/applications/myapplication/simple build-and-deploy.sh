#!/bin/bash

# Input variables
INTEGRATION_NODE="${INTEGRATION_NODE:-IN2}"         # Default node name
INTEGRATION_SERVER="${INTEGRATION_SERVER:-IS2}"     # Default server name
BAR_FILE_NAME="${BAR_FILE_NAME:-STAT_LIBproject.generated.bar}" # Default BAR file name
WORKSPACE_DIR="${WORKSPACE_DIR:-.}"                # Default workspace directory
APPLICATION_NAME="${APPLICATION_NAME:-STAT_LIB}"   # Default application/library name

# Build the BAR file
echo "Building BAR file: $BAR_FILE_NAME"
mqsipackagebar -w "$WORKSPACE_DIR" -a "$BAR_FILE_NAME" -k "$APPLICATION_NAME"
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate BAR file."
  exit 1
fi
echo "BAR file generated successfully: $BAR_FILE_NAME"

# Deploy the BAR file
echo "Deploying BAR file to Integration Node: $INTEGRATION_NODE, Server: $INTEGRATION_SERVER"
mqsideploy -n "$INTEGRATION_NODE" -e "$INTEGRATION_SERVER" -a "$BAR_FILE_NAME"
if [ $? -ne 0 ]; then
  echo "Error: Deployment failed."
  exit 1
fi
echo "BAR file deployed successfully!"

