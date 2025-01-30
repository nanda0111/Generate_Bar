#!/bin/bash

# Variables
REPO_URL="https://github.com/nanda0111/Generate_Bar_G.git"  # Replace with your actual repository URL
INTEGRATION_NODE="IN8"
INTEGRATION_SERVER="IE8"
WORKSPACE_DIR="./workspace"
#BAR_FILE_NAME="static_app-demo.bar"
#BAR_FILE_DIR="./bar-files"
#BAR_FILE="$BAR_FILE_DIR/$BAR_FILE_NAME"
#APPLICATION_NAME="static_app_workspace"
PROPERTY_FILE="./config/override.properties"
LOCAL_STORAGE_DIR="./file-bar"  # Local system folder for final output

LOG_FILE="./build.log"

# Ensure necessary directories exist
mkdir -p "$BAR_FILE_DIR"
mkdir -p "$LOCAL_STORAGE_DIR"

# Step 1: Clone or pull the latest source code from GitHub
if [ ! -d "Generate_Bar_G" ]; then
  echo "Cloning repository..." | tee -a $LOG_FILE
  git clone "$REPO_URL"
else
  echo "Updating repository..." | tee -a $LOG_FILE
  cd Generate_Bar_G || exit 1
  git pull origin main || { echo "Error: Failed to pull latest changes"; exit 1; }
  cd ..
fi

# Step 2: Copy the latest source code & properties into the local workspace
cp -r Generate_Bar_G/workspace/* "$WORKSPACE_DIR/"
cp Generate_Bar_G/config/override.properties "$PROPERTY_FILE"

# Step 3: Generate BAR file
echo "Generating BAR file..." | tee -a $LOG_FILE
mqsicreatebar -data "$WORKSPACE_DIR" -b "$BAR_FILE" -a "$APPLICATION_NAME" 2>&1 | tee -a $LOG_FILE

# Step 4: Check if BAR file was created
if [ ! -f "$BAR_FILE" ]; then
  echo "Error: BAR file was not created!" | tee -a $LOG_FILE
  exit 1
fi

# Step 5: Override property file
echo "Overriding property file..." | tee -a $LOG_FILE
sed -i 's/old_value/new_value/g' "$PROPERTY_FILE"

# Step 6: Push the updated property file back to GitHub
cd Generate_Bar_G || exit 1
git add config/override.properties
git commit -m "Updated override.properties file"
git push origin main
cd ..

# Step 7: Move final BAR file to local system folder
mv "$BAR_FILE" "$LOCAL_STORAGE_DIR/"

echo "Process completed successfully!" | tee -a $LOG_FILE
exit 0

