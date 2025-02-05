#!/bin/bash

# Variables
INTEGRATION_NODE="INB"
INTEGRATION_SERVER="ISB"

# Paths for GitHub-hosted directories
GITHUB_WORKSPACE="./workspace/"  # Workspace stored in GitHub
GITHUB_CONFIG="./config/override.properties"  # Property file stored in GitHub
GITHUB_WORKFLOW_DIR="./.github/workflows/"  # Path to GitHub Actions workflows
GITHUB_WORKFLOW_FILE="$GITHUB_WORKFLOW_DIR/update-properties.yml"  # Workflow file
GITHUB_TOKEN="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"  # personal access token for my git repository

# Paths for locally stored directories
BAR_FILE_DIR="/home/ace/Generate_Bar/bar-files"  # Local directory for BAR files
BAR_FILE_NAME="http_demo.bar"
BAR_FILE="$BAR_FILE_DIR/$BAR_FILE_NAME"
APPLICATION_NAME="feb3"
LOCAL_STORAGE_DIR="/home/ace/Generate_Bar/file-bar"  # Local storage for final output
TEMP_PROPERTY_FILE="/home/ace/Generate_Bar/config/bar_generated.properties"  # Temporary extracted properties

LOG_FILE="./buildHTTP.log"  # Store logs in project directory

# Ensure necessary directories exist (only for local folders)
mkdir -p "$BAR_FILE_DIR"
mkdir -p "$LOCAL_STORAGE_DIR"

# Step 1: Verify Source Files Exist in GitHub Workspace
if [ ! -d "$GITHUB_WORKSPACE/$APPLICATION_NAME" ]; then
  echo "Error: Application '$APPLICATION_NAME' not found in $GITHUB_WORKSPACE!" | tee -a $LOG_FILE
  exit 1
fi

# Step 2: Generate BAR file
echo "Generating BAR file for $APPLICATION_NAME..." | tee -a $LOG_FILE
mqsicreatebar -data "$GITHUB_WORKSPACE" -b "$BAR_FILE" -a "$APPLICATION_NAME" 2>&1 | tee -a $LOG_FILE

# Step 3: Check if BAR file was created
if [ ! -f "$BAR_FILE" ]; then
  echo "Error: BAR file was not created!" | tee -a $LOG_FILE
  exit 1
fi
echo "BAR file successfully created: $BAR_FILE" | tee -a $LOG_FILE

# Step 4: Extract Property Values from Generated BAR File
echo "Extracting properties from the generated BAR file..." | tee -a $LOG_FILE
mqsireadbar -b "$BAR_FILE" -r > "$TEMP_PROPERTY_FILE"

# Step 5: Replace Values in `override.properties` (Stored in GitHub)
if [ -f "$GITHUB_CONFIG" ]; then
  echo "Updating existing property file with new values..." | tee -a $LOG_FILE
  while IFS= read -r line; do
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)
    if grep -q "^$key=" "$GITHUB_CONFIG"; then
      sed -i "s|^$key=.*|$key=$value|" "$GITHUB_CONFIG"
    else
      echo "$line" >> "$GITHUB_CONFIG"
    fi
  done < "$TEMP_PROPERTY_FILE"
else
  echo "No existing property file found! Using new properties from the BAR file." | tee -a $LOG_FILE
  mv "$TEMP_PROPERTY_FILE" "$GITHUB_CONFIG"
fi

# Step 6: Apply Updated Property Overrides to the BAR File
echo "Applying updated property values to the BAR file..." | tee -a $LOG_FILE
mqsiapplybaroverride -b "$BAR_FILE" -p "$GITHUB_CONFIG" -r

# Step 7: Move Final BAR File & Updated Property File to Local Storage
mv "$BAR_FILE" "$LOCAL_STORAGE_DIR/"
cp "$GITHUB_CONFIG" "$LOCAL_STORAGE_DIR/"

# Step 8: Commit and Push Updated Property File to GitHub (Trigger Workflow)
echo "Committing updated property file to GitHub..." | tee -a $LOG_FILE
git add "$GITHUB_CONFIG"
git commit -m "Updated override.properties with new values"
git push origin main

# Step 9: Trigger GitHub Actions Workflow
echo "Triggering GitHub Actions workflow: update-properties.yml..." | tee -a $LOG_FILE
curl -X POST -H "Accept: application/vnd.github.v3+json" \
     -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/nanda0111/Generate_Bar/actions/workflows/update-properties.yml/dispatches \
     -d '{"ref":"main"}'

echo "Process completed successfully!" | tee -a $LOG_FILE
exit 0

