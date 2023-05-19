#!/bin/bash

# https://mycroft.ai/mimic-3/

# Get the file name without the extension
filename=$(basename -- "$1")
filename="${filename%.*}"

# New parameters for language and voice
language="$2"
voice="$3"
speaker="$4" # New speaker parameter

# Output path
output_path="/home/$(id -u -n)/Music/Mimic3/"
[ ! -d ${output_path} ] &&
mkdir -p ${output_path}

# Set the quality variable (default is 9, where 9 is the lowest quality and 1 is the best quality)
quality="${5:-9}"

# Speed of speech (default is 1, where > 1 is slower, < 1 is faster)
speed_en="${6:-1}"
speed_de="${6:-1}"

# Extract the first two letters of language
lang_prefix="${language:0:2}"

# Determine which speed variable to use based on language
if [[ "$lang_prefix" == "en" ]]; then
    speed="$speed_en"
elif [[ "$lang_prefix" == "de" ]]; then
    speed="$speed_de"
else
    speed="1"
fi

# Add the language prefix to the filename
output_filename="${filename}_$lang_prefix"

# Boolean variable to control whether to filter code blocks (default is true)
filter_code_blocks="${7:-true}"

# Make a temporary copy of the file
temp_file="/tmp/${output_filename}_temp.md"
cp "$1" "$temp_file"

# Check language and set the skip message accordingly
if [[ "$lang_prefix" == "de" ]]; then
    skip_message="überspringe code block"
else
    skip_message="skipping code block"
fi

# Replace code blocks with skip message if filter_code_blocks is true
if [[ "$filter_code_blocks" == "true" ]]; then
    sed -i '/```/,/```/c\ '"$skip_message" "$temp_file"
fi

# Convert markdown to plain text (if necessary)
pandoc --wrap=none "$temp_file" -t plain -o "/tmp/${output_filename}.txt"

# Combine language, voice and (optional) speaker parameters (for mimic3 syntax)
if [ -z "$speaker" ]; then
    voice_param="${language}/${voice}"
else
    voice_param="${language}/${voice}#${speaker}"
fi

# Convert content to speech using Mimic3 TTS
cat "/tmp/${output_filename}.txt" | /home/rrichardson/.local/bin/mimic3 --voice "$voice_param" --length-scale "$speed" | ffmpeg -i pipe:0 -codec:a libmp3lame -qscale:a "$quality" "/tmp/${output_filename}.mp3"

# If output path is set, move the output files there
if [ -n "$output_path" ]; then
    mv "/tmp/${output_filename}.mp3" "${output_path}${output_filename}.mp3"
fi

# Remove temporary files
rm "$temp_file"
rm "/tmp/${output_filename}.txt"
