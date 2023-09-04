#!/bin/bash

# Checking if input is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input directory or file> [output directory or file]"
    exit 1
fi

input=$1
output=$2

# Function to compress a single file
compress_file() {
    input_file=$1
    output_file=$2

    if [[ $input_file == *.pdf ]]; then
        # Compressing PDF file and saving it to the output directory
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
        -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$output_file" "$input_file"
    elif [[ $input_file == *.jpg || $input_file == *.png || $input_file == *.jpeg ]]; then
        # Check if the input image file size is less than 1MB
        if [ $(stat -c%s "$input_file") -le 1048576 ]; then
            # Convert to jpg if not already
            if [[ $input_file != *.jpg && $input_file != *.jpeg ]]; then
                convert "$input_file" "$output_file"
            fi
        else
            # Compress and convert image file to jpg
            convert "$input_file" -resize 300x300 -quality 85 -strip "$output_file"
        fi
    fi
}

if [ -f "$input" ]; then
    # If input is a file
    if [ -z "$output" ]; then
        # If no output file is given
        base_name=$(basename "$input" | cut -d. -f1)
        dir_name=$(dirname "$input")
        output="$dir_name/${base_name}_compressed.jpg"
    fi

    compress_file "$input" "$output"
elif [ -d "$input" ]; then
    # If input is a directory
    find "$input" \( -iname '*.pdf' -o -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) -type f | while read -r file; do
        if [ -z "$output" ]; then
            # If no output directory is given
            base_name=$(basename "$file" | cut -d. -f1)
            dir_name=$(dirname "$file")
            output_file="$dir_name/${base_name}_compressed.jpg"
        else
            # If output directory is given, maintain the same directory structure
            output_file="${file/$input/$output}"
            output_dir=$(dirname "$output_file")

            # Creating directories if they do not exist
            mkdir -p "$output_dir"
        fi

        compress_file "$file" "$output_file"
    done
else
    echo "Invalid input. Please provide a valid file or directory."
    exit 1
fi

exit 0
