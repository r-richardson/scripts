#!/bin/bash

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 IMAGE_DIR OUTPUT_DIR [LANGUAGE_CODE]"
  exit 1
fi

# Directory containing image files to be processed
IMAGE_DIR=$1

# Output directory for text files
OUTPUT_DIR=$2

# Optional language code for Tesseract OCR
LANGUAGE_CODE=${3:-eng}

if ! command -v tesseract &> /dev/null; then
  echo "Tesseract is not installed. Please install Tesseract OCR to proceed."
  exit 1
fi

if mkdir -p "$OUTPUT_DIR"; then
  echo "Output directory: '$OUTPUT_DIR'"
else
  echo "Failed to create output directory '$OUTPUT_DIR'."
  exit 1
fi

for image in "$IMAGE_DIR"/*; do
  if [[ -f $image ]]; then
    echo "Processing $image..."
    base_name=$(basename "$image" | sed 's/\.[^.]*$//')
    if tesseract "$image" "$OUTPUT_DIR/$base_name" -l "$LANGUAGE_CODE"; then
      echo "$image processed and saved as $OUTPUT_DIR/$base_name.txt"
    else
      echo "Failed to process $image."
    fi
  fi
done

echo "All images processed."

