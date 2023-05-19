#!/bin/bash

# This script watches a folder for new, or changed files of given types
# It then passes parent directory names to use as parameters for the script call

# Directory to watch
dir_to_watch=${1:-""}

# Define the target script
target_script=${2:-"./text_to_speech.sh"}

# Define the file types to watch
file_types=("md" "txt")

# Watch the directory
inotifywait -m -r "$dir_to_watch" -e create -e moved_to |
    while read path action file; do
        for type in "${file_types[@]}"; do
            # If the file is of given type
            if [[ $file =~ .$type$ ]]; then
                # Extract language, voice and speaker from path
                # Remove the base directory from path
                sub_path="${path#$dir_to_watch}"
                # Remove leading and trailing slashes
                sub_path="${sub_path#/}"
                sub_path="${sub_path%/}"
                # Extract language, voice and speaker (named assuming script is used for mimic3 tts)
                IFS='/' read -r language voice speaker <<< "$sub_path"
                # Convert it to speech with speaker
                $target_script "$path$file" "$language" "$voice" "$speaker"
                # Break the loop as soon as a match is found
                break
            fi
        done
    done
