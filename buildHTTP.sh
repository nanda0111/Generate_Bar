#!/bin/bash

# Variables
INTEGRATION_NODE="INB"
INTEGRATION_SERVER="ISB"
WORKSPACE_DIR="/home/ace/IBM/ACET12/workspace/"
BAR_FILE_DIR="/home/ace/Generate_Bar/bar-files"
BAR_FILE_NAME="http_demo.bar"
BAR_FILE="$BAR_FILE_DIR/$BAR_FILE_NAME"
APPLICATION_NAME="feb3"
PROPERTY_FILE="/home/ace/Generate_Bar/config/override.properties"  # Existing property file
TEMP_PROPERTY_FILE="/home/ace/Generate_Bar/config/bar_generated.properties"  # Properties extracted from BAR file
LOCAL_STORAGE_DIR="/home/ace/Generate_Bar/file-bar"  # Local folder for final output

LOG_FILE="/var/log/ace/buildHTTP.log"

# Ensure necessary directories exist
mkdir -p "$BAR_FILE_DIR"
mkdir -p "$LOCAL_STORAGE_DIR"

# Step 1: Verify Source Files Exist
if [ ! -d "$WORKSPACE_DIR/$APPLICATION_NAME" ]; then
  echo "Error: Application '$APPLICATION_NAME' not found in $WORKSPACE_DIR!" | tee -a $LOG_FILE
  exit 1
fi

# Step 2: Generate BAR file
echo "Generating BAR file for $APPLICATION_NAME..." | tee -a $LOG_FILE
mqsicreatebar -data "$WORKSPACE_DIR" -b "$BAR_FILE" -a "$APPLICATION_NAME" 2>&1 | tee -a $LOG_FILE

# Step 3: Check if BAR file was created
if [ ! -f "$BAR_FILE" ]; then
  echo "Error: BAR file was not created!" | tee -a $LOG_FILE
  exit 1
fi
echo "BAR file successfully created: $BAR_FILE" | tee -a $LOG_FILE

# Step 4: Extract Property Values from Generated BAR File
echo "Extracting properties from the generated BAR file..." | tee -a $LOG_FILE
mqsireadbar -b "$BAR_FILE" -r > "$TEMP_PROPERTY_FILE"

# Step 5: Replace Values in `override.properties` with New Properties
if [ -f "$PROPERTY_FILE" ]; then
  echo "Updating existing property file with new values..." | tee -a $LOG_FILE
  while IFS= read -r line; do
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)
    if grep -q "^$key=" "$PROPERTY_FILE"; then
      sed -i "s|^$key=.*|$key=$value|" "$PROPERTY_FILE"
    else
      echo "$line" >> "$PROPERTY_FILE"
    fi
  done < "$TEMP_PROPERTY_FILE"
else
  echo "No existing property file found! Using new properties from the BAR file." | tee -a $LOG_FILE
  mv "$TEMP_PROPERTY_FILE" "$PROPERTY_FILE"
fi

# Step 6: Apply Updated Property Overrides to the BAR File
echo "Applying updated property values to the BAR file..." | tee -a $LOG_FILE
mqsiapplybaroverride -b "$BAR_FILE" -p "$PROPERTY_FILE" -r

# Step 7: Move Final BAR File & Updated Property File to Local Storage
mv "$BAR_FILE" "$LOCAL_STORAGE_DIR/"
cp "$PROPERTY_FILE" "$LOCAL_STORAGE_DIR/"

echo "Process completed successfully!" | tee -a $LOG_FILE
exit 0

