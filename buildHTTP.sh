#!/bin/bash

# Variables
INTEGRATION_NODE="INB"
INTEGRATION_SERVER="ISB"
GITHUB_REPO="https://github.com/nanda0111/Generate_Bar.git"
GITHUB_BRANCH="main"

# Paths for GitHub-hosted directories
GITHUB_WORKSPACE="/home/ace/Generate_Bar/workspace/applications/"
GITHUB_CONFIG="/home/ace/Generate_Bar/config/override.properties"
GITHUB_WORKFLOW_DIR="/home/ace/Generate_Bar/.github/workflows/"
GITHUB_WORKFLOW_FILE="$GITHUB_WORKFLOW_DIR/update-properties.yml"

# Paths for locally stored directories
BAR_FILE_DIR="/home/ace/Generate_Bar/bar-files"
BAR_FILE_NAME="http_demo.bar"
BAR_FILE="$BAR_FILE_DIR/$BAR_FILE_NAME"
APPLICATION_NAME="feb3"
LOCAL_STORAGE_DIR="/home/ace/Generate_Bar/file-bar"
TEMP_PROPERTY_FILE="/home/ace/Generate_Bar/config/bar_generated.properties"

LOG_FILE="./buildHTTP.log"

# Ensure necessary directories exist
mkdir -p "$BAR_FILE_DIR"
mkdir -p "$LOCAL_STORAGE_DIR"

# Step 1: Clone the Latest GitHub Repository
echo "Cloning the latest source code from GitHub..." | tee -a $LOG_FILE
if [ -d "/home/ace/Generate_Bar/.git" ]; then
    cd /home/ace/Generate_Bar
    git reset --hard
    git pull origin $GITHUB_BRANCH
else
    git clone --branch $GITHUB_BRANCH $GITHUB_REPO /home/ace/Generate_Bar
fi

# Step 2: Ensure the "file-bar" directory exists locally
if [ ! -d "$LOCAL_STORAGE_DIR" ]; then
    echo "Creating 'file-bar' directory locally..." | tee -a $LOG_FILE
    mkdir -p "$LOCAL_STORAGE_DIR"
else
    echo "'file-bar' directory already exists locally." | tee -a $LOG_FILE
fi

# Step 3: Ensure the "file-bar" directory exists in GitHub
cd /home/ace/Generate_Bar
if [ ! -d "file-bar" ]; then
    echo "Creating 'file-bar' directory in GitHub..." | tee -a $LOG_FILE
    mkdir -p file-bar
    git add file-bar
    git commit -m "Created file-bar directory"
    git push origin $GITHUB_BRANCH
else
    echo "'file-bar' directory already exists in GitHub." | tee -a $LOG_FILE
fi

# Step 4: Verify Source Files Exist in GitHub Workspace
if [ ! -d "$GITHUB_WORKSPACE/$APPLICATION_NAME" ]; then
  echo "Error: Application '$APPLICATION_NAME' not found in $GITHUB_WORKSPACE!" | tee -a $LOG_FILE
  exit 1
fi

# Step 5: Generate BAR file using GitHub Source Files
echo "Generating BAR file for $APPLICATION_NAME using GitHub source files..." | tee -a $LOG_FILE
mqsicreatebar -data "$GITHUB_WORKSPACE" -b "$BAR_FILE" -a "$APPLICATION_NAME" 2>&1 | tee -a $LOG_FILE

# Step 6: Check if BAR file was created
if [ ! -f "$BAR_FILE" ]; then
  echo "Error: BAR file was not created!" | tee -a $LOG_FILE
  exit 1
fi
echo "BAR file successfully created: $BAR_FILE" | tee -a $LOG_FILE

# Step 7: Extract Property Values from Generated BAR File
echo "Extracting properties from the generated BAR file..." | tee -a $LOG_FILE
mqsireadbar -b "$BAR_FILE" -r > "$TEMP_PROPERTY_FILE"

# Step 8: Replace Values in override.properties
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

# Step 9: Apply Updated Property Overrides to the BAR File
echo "Applying updated property values to the BAR file..." | tee -a $LOG_FILE
mqsiapplybaroverride -b "$BAR_FILE" -p "$GITHUB_CONFIG" -r

# Step 10: Move Final BAR File & Updated Property File to Local Storage
echo "Moving final BAR file and updated property file to local storage..." | tee -a $LOG_FILE
cp "$BAR_FILE" "$LOCAL_STORAGE_DIR/"
cp "$GITHUB_CONFIG" "$LOCAL_STORAGE_DIR/override.properties"

# Step 11: Move Final BAR File & Updated Property File to GitHub
echo "Moving final BAR file and updated property file to GitHub..." | tee -a $LOG_FILE
cp "$LOCAL_STORAGE_DIR/$BAR_FILE_NAME" /home/ace/Generate_Bar/file-bar/
cp "$LOCAL_STORAGE_DIR/override.properties" /home/ace/Generate_Bar/file-bar/

# Step 12: Commit and Push Updated Property File & BAR File to GitHub
cd /home/ace/Generate_Bar
git add file-bar/http_demo.bar
git add file-bar/override.properties
git commit -m "Updated BAR file and override.properties"
git push origin $GITHUB_BRANCH

# Step 13: Trigger GitHub Actions Workflow
echo "Triggering GitHub Actions workflow: update-properties.yml..." | tee -a $LOG_FILE
curl -X POST -H "Accept: application/vnd.github.v3+json" \
     -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/nanda0111/Generate_Bar/actions/workflows/update-properties.yml/dispatches \
     -d '{"ref":"main"}'

echo "Process completed successfully!" | tee -a $LOG_FILE
exit 0

