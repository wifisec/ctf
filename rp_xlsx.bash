#!/usr/bin/env bash

# Bash script to remove sheet protection from an Excel .xlsx file.
# - Backs up the original file before processing.
# - Creates a new .xlsx file with sheet protection removed.
# - Requires unzip, sed, and zip utilities.
# - Displays usage information if no arguments are provided.
#
# Author: Adair John Collins
# Version: 1.0 (Initial release, [03082025])

# Function to display usage
usage() {
    echo "Usage: $0 input.xlsx [output.xlsx]"
    echo "  - input.xlsx: The Excel file to process."
    echo "  - output.xlsx: Optional output file (default: input_unprotected.xlsx)."
    exit 1
}

# Check if at least one argument is provided; if not, show usage
if [ $# -lt 1 ]; then
    usage
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.xlsx}_unprotected.xlsx}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' does not exist."
    exit 1
fi

# Create a backup of the original file
BACKUP_FILE="${INPUT_FILE}.bak"
echo "Creating backup: $BACKUP_FILE"
cp "$INPUT_FILE" "$BACKUP_FILE" || {
    echo "Error: Failed to create backup."
    exit 1
}

# Create a temporary directory to work in
TEMP_DIR=$(mktemp -d)
echo "Working in temporary directory: $TEMP_DIR"

# Unzip the .xlsx file (it's a ZIP archive)
unzip -q "$INPUT_FILE" -d "$TEMP_DIR" || {
    echo "Error: Failed to unzip '$INPUT_FILE'."
    exit 1
}

# Remove sheet protection by editing the XML files
# Look for sheetProtection tags in xl/worksheets/*.xml
for xml_file in "$TEMP_DIR/xl/worksheets/"sheet*.xml; do
    if grep -q "sheetProtection" "$xml_file"; then
        echo "Removing protection from: $xml_file"
        # Remove the entire sheetProtection tag
        sed -i 's/<sheetProtection[^>]*\/>//g' "$xml_file"
    fi
done

# Recreate the .xlsx file
cd "$TEMP_DIR" || exit 1
zip -q -r "$OUTPUT_FILE" * || {
    echo "Error: Failed to create new .xlsx file."
    exit 1
}
cd - >/dev/null

# Move the new file to the original directory
mv "$TEMP_DIR/$OUTPUT_FILE" "$(dirname "$INPUT_FILE")/$OUTPUT_FILE" || {
    echo "Error: Failed to move output file."
    exit 1
}

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "New unprotected file saved as: $OUTPUT_FILE"
