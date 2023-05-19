# Directory Monitoring and Text-to-Speech Conversion Script

## Project Description

This script monitors a specified directory for new or modified markdown (`.md`) or text (`.txt`) files. When such a file is detected, the script retrieves parameters from the file's directory structure and passes them, along with the file, to a Text-to-Speech (TTS) conversion script. The file types which are being watched for, as well as the script which the files and parameters are passed to, are customizable within the script.

## Table of Contents

1. [Project Description](#project-description)
2. [Prerequisites](#prerequisites)
3. [Installation and Running](#installation-and-running)
4. [Systemd Service File](#systemd-service-file)
5. [Usage](#usage)
6. [Contributing](#contributing)
7. [License](#license)

## Prerequisites

Before you begin, ensure you have met the following requirements:
* You have a Linux machine.
* You have installed the `inotify-tools` package.
* You have a Text-to-Speech conversion script (the default is my `text_to_speech.sh` located in the same directory).

## Installation and Running

To install and run this script, follow these steps:
1. Clone the repository or download the script to your local machine.
2. Make the script executable by running `chmod +x script.sh`.
3. To run the script, use the following command: `./monitor_directory.sh directory_to_watch text_to_speech_script`
	- Replace `directory_to_watch` with the path to the directory you want to monitor
	- (optional) Replace `text_to_speech_script` with the path to your script.

## Systemd Service File

To make this script run as a service, you can use a systemd service file. Here's how to set it up:
1. Create a service file in `/etc/systemd/system/`, e.g., `tts.service`:

		[Unit]
		Description=Text to Speech Service

		[Service]
		ExecStart=./text_to_speech.sh "/PATH/TO/WATCHDIR/"
		Restart=always
		User=[USERNAME]                             			# <- change this
		Group=[GROUP]                               			# <- change this
		Environment=PATH=/usr/bin:/usr/local/bin
		Environment=NODE_ENV=production
		WorkingDirectory=[/PATH/TO/SCRIPTDIR]        			# <- change this

		[Install]
		WantedBy=multi-user.target

2. Modify the `ExecStart`, `User`, `Group`, and `WorkingDirectory` fields to fit your setup.
    * `ExecStart`: Path to your Text-to-Speech conversion script.
    * `User` and `Group`: The user and group under which the service should run.
    * `WorkingDirectory`: The directory where the script resides.
3. Once you've made these changes, save and close the file.
4. Enable the service by running `sudo systemctl enable tts.service`.
5. Start the service by running `sudo systemctl start tts.service`.
6. You can check the status of the service anytime by running `sudo systemctl status tts.service`.

## Usage

This script monitors a specified directory for newly created or moved-in markdown (`.md`) or text (`.txt`) files. Once such a file is detected, it retrieves parameters from the file's directory structure, such as language, voice, and speaker, and calls a Text-to-Speech conversion script with these parameters and the file. The directory structure is expected to be as follows: `language/voice/speaker`.

## Contribution

Contributions are welcome. If you find a bug, please open an issue. If you want to make a change to the code, please fork the repository and make a pull request.

## License

This project uses the following license: [MIT License](../LICENSE).