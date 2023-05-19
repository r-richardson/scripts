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