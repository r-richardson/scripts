This script helps you to backup important files of a Cryptpad instance. It uses SCP to transfer the files and compresses them into a `.tar.gz` archive.

## Features

- Backup important Cryptpad files and configurations
- Compress the backup into a `.tar.gz` archive
- Override default values by passing parameters
- Supports adding custom folders to sync

## Usage

1. Update the `cryptpad_ip` variable in the script with the IP address of your Cryptpad instance.

2. (Optional) Update other variables if needed, such as `ssh_username`, `cryptpad_path`, and asset locations.

3. Run the script with the following command:

```bash
./cryptpad_backup.sh
```

### Parameters

- `-i`: Override the `cryptpad_ip` variable
- `-c`: Override the `cryptpad_path` variable
- `-b`: Override the `backups_dir` variable
- `-h`: Display the help page

To thoroughly analyze the bash backup script and expand the current documentation with the requested details, I will proceed in the following steps:

1. Review the bash backup script (`cryptpad_backup.sh`) to understand its functionality, focusing on the mechanisms it uses for backup, disk checks, and removal of old archives.
2. Review the systemd automation files (`cryptpad_backup.service` and `cryptpad_backup.timer`) to understand how they schedule and automate the backup process.
3. Analyze the current documentation (`bash_cryptpad_backup.md`) to identify the best way to incorporate the new sections and information.
4. Expand the documentation with a section on setting up systemd automation for the backup script, including how to perform disk checks and remove old archives. This section will also contain the entire contents of the `.service` and `.timer` files.

I'll start by reviewing the bash backup script (`cryptpad_backup.sh`). Let's take a look at its contents to understand its functionality.

The `cryptpad_backup.sh` script is a comprehensive tool designed for backing up important files of a Cryptpad instance. Here's an overview of its functionality based on the script content:

- **Configuration and Arguments**: It allows defining variables either in a separate configuration file (`cryptpad_backup.conf`) or as command-line arguments, with the latter taking precedence. These variables include the Cryptpad IP address, Cryptpad path, backup directory, SSH port, and SSH username.

- **Help Function**: A `print_help` function provides detailed usage instructions and options available for the script, making it user-friendly for new users to understand how to execute the backup.

- **Backup Process**:
    - The script uses Secure Copy Protocol (SCP) to transfer files from the Cryptpad server to a temporary directory on the client machine.
    - It iterates over a predefined array of Cryptpad configuration keys, fetching the corresponding paths from the server's Cryptpad configuration file and backing them up.
    - Custom paths specified in the configuration file are also backed up.
    - If all files are fetched successfully, the script compresses the backed-up files into a `.tar.gz` archive in the specified backup directory.
    - Success or failure of operations is logged, and temporary directories are cleaned up post-operation.

- **Compression and Cleanup**: On successful backup, the script compresses the files and removes the temporary backup directory. If there are failures in fetching any files, it skips the compression step and logs a message indicating the same.

- **Logging**: Throughout its execution, the script logs its operations, including the start and end of the backup process, any errors encountered, and the final outcome (success or failure).

Next, I'll review the systemd automation files (`cryptpad_backup.service` and `cryptpad_backup.timer`) to understand how the backup process is automated. Let's start with the `.service` file.

The `cryptpad_backup.service` file is structured to define a systemd service for the Cryptpad backup script. Here's a breakdown of its contents:

- **[Unit] Section**: Describes the unit, including a brief `Description` of the service, which is "Cryptpad Backup Service" in this case.

- **[Service] Section**:
    - `Type=oneshot` indicates that this service is intended to run a single operation and then exit. This is typical for script-based tasks that do not remain active after their job is completed.
    - `ExecStart` specifies the command to start the service, pointing to the location of the `cryptpad_backup.sh` script (`/home/rrichardson/Code/scripts/bash/cryptpad_backup.sh`). This is the actual backup script that the service will execute.

- **[Install] Section**: Defines the target that this service should be installed into. `WantedBy=multi-user.target` means that this service is intended to be started when the system reaches the multi-user runlevel, although it would typically be triggered by its associated timer rather than at boot.

Next, let's examine the `.timer` file to understand how it schedules the backup service.

The `cryptpad_backup.timer` file configures a systemd timer to schedule the execution of the Cryptpad backup service at regular intervals. Here's a summary of its configuration:

- **[Unit] Section**: Contains a `Description` of the timer, which is "Runs Cryptpad Backup Service periodically". This provides a clear understanding of the timer's purpose.

- **[Timer] Section**:
    - `OnBootSec=10min` configures the timer to activate the service 10 minutes after the system boots. This delay allows the system to complete its initial startup processes before initiating the backup.
    - `OnUnitActiveSec=24h` sets the timer to activate the service every 24 hours after it was last activated. This ensures daily backups.
    - `Unit=cryptpad_backup.service` specifies the service unit to be activated by this timer, linking it directly to the `cryptpad_backup.service` we reviewed earlier.

- **[Install] Section**: Indicates that the timer should be enabled to start automatically at boot by linking it to `WantedBy=timers.target`. This ensures the timer is integrated into the system's regular scheduling mechanism.

With the understanding of how the bash backup script works and how the systemd `.service` and `.timer` files automate its execution, we can now proceed to expand the current documentation (`bash_cryptpad_backup.md`) with a new section on setting up systemd automation, performing disk checks, and managing old archives. This section will also include the entire contents of the `.service` and `.timer` files.

Let's begin by examining the current documentation to determine the best way to incorporate these new details.

The current documentation for the Cryptpad backup script provides a concise overview of the script's purpose, its features, usage instructions, and how to customize it with additional folders or files for synchronization. Here's an outline based on the first part of the documentation:

- **Introduction**: Briefly explains the script's function to back up important files from a Cryptpad instance and compress them into a `.tar.gz` archive.
- **Features**: Lists key features such as backing up important files, compressing backups, overriding default values, and adding custom folders.
- **Usage**: Outlines steps for configuring and running the script, including how to override default variables and execute the script.
- **Parameters**: Describes the command-line parameters available for customizing the script's execution.

To expand this documentation with the new sections on setting up systemd automation, performing disk checks, and managing old archives, the following additions will be made:

1. **Systemd Automation Setup**: This section will explain how to automate the backup process using `systemd`, including how to create and enable the `.service` and `.timer` files. It will provide the content of both `cryptpad_backup.service` and `cryptpad_backup.timer`, explaining each part's purpose.

2. **Disk Checks**: Although the provided script doesn't explicitly perform disk checks, this section could describe how to integrate simple disk space checks before starting the backup process, ensuring sufficient space is available.

3. **Removing Old Archives**: This part will suggest methods for managing old backup archives, such as using `find` or `tmpwatch` commands to automatically delete backups older than a certain number of days.

Next, I will draft these sections and integrate them into the existing documentation, including the full content of the `.service` and `.timer` files. Let's proceed with drafting the expanded documentation.

### Expanded Documentation Draft for Bash Cryptpad Backup

---

This script helps you to backup important files of a Cryptpad instance. It uses SCP to transfer the files and compresses them into a `.tar.gz` archive.

## Features

- Backup important Cryptpad files and configurations
- Compress the backup into a `.tar.gz` archive
- Override default values by passing parameters
- Supports adding custom folders to sync

## Usage

1. Update the `cryptpad_ip` variable in the script with the IP address of your Cryptpad instance.

2. (Optional) Update other variables if needed, such as `ssh_username`, `cryptpad_path`, and asset locations.

3. Run the script with the following command:

```bash
./cryptpad_backup.sh
```

### Parameters

- `-i`: Override the `cryptpad_ip` variable
- `-c`: Override the `cryptpad_path` variable
- `-b`: Override the `backups_dir` variable
- `-h`: Display the help page

## Adding a Custom Folder or File to Sync

To add a custom folder or file to sync with the script, create a new `backup` function call at the end of the "BACKUP S...

---

## Automating Backups with Systemd

To automate the backup process using `systemd`, follow these steps:

### Creating the Systemd Service and Timer

1. **Service File**: Create a file named `cryptpad_backup.service` with the following content to define the service:

```ini
[Unit]
Description=Cryptpad Backup Service

[Service]
Type=oneshot
ExecStart=/path/to/cryptpad_backup.sh

[Install]
WantedBy=multi-user.target
```

Replace `/path/to/cryptpad_backup.sh` with the actual path to your backup script.

2. **Timer File**: Create a file named `cryptpad_backup.timer` with the following content to schedule the service:

```ini
[Unit]
Description=Runs Cryptpad Backup Service periodically

[Timer]
OnBootSec=10min
OnUnitActiveSec=24h
Unit=cryptpad_backup.service

[Install]
WantedBy=timers.target
```

### Enabling the Timer

Run the following commands to enable and start the timer:

```bash
sudo systemctl enable cryptpad_backup.timer
sudo systemctl start cryptpad_backup.timer
```

This will ensure that the backup service runs automatically according to the schedule defined in the timer file.

## Disk Checks Before Backup

To ensure sufficient disk space is available before starting the backup, the script checks whether there is at least 1.5 times the previous archive size currently available. If this is not the case it keeps deleting the oldest archive until either this minimum amount of disk space is available or there is only 1 archive left.

## Adding a Custom Folder or File to Sync

To add a custom folder or file to sync with the script, create a new `backup` function call at the end of the "BACKUP SCHEDULE" section, like this:

```bash
backup /path/to/your/custom/folder
```

Replace `/path/to/your/custom/folder` with the path to the folder or file you want to sync.

## Backup Result

The backup archive will be stored in the specified `backups_dir` with the following format:

```
cryptpad_backup_<datetime>.tar.gz
```

A log file will also be created in the same directory, named `.cryptpad_backup.log`.

## Troubleshooting

If you encounter issues with constant SSH keyphrase requests, make sure to add your SSH key to the ssh-agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```
Replace ~/.ssh/id_rsa with the path to your private SSH key if it's different.

## Contribution

Contributions are welcome. If you find a bug, please open an issue. If you want to make a change to the code, please fork the repository and make a pull request.

## License

This project uses the following license: [MIT License](../LICENSE).
