# BackupTool

**BackupTool** is a simple, user-friendly disk backup utility for Windows.  
It allows non-technical users to perform complete, incremental, differential, or dry-run backups of a disk or folder using a graphical interface, while relying on the robustness of **RoboCopy** in the background.

The tool is designed to be:

- ✅ Easy to use (GUI-based)
- ✅ Safe for multiple users
- ✅ Reliable for large disk backups
- ✅ Suitable for personal or small professional environments

---

## 🚀 Features

- **Complete backup** (Mirror)
- **Incremental backup** (only newer files)
- **Differential backup** (since last full backup)
- **Dry-run mode** (simulation, no data copied)
- Automatic date-labeled backup folders
- Per-user log files
- Graphical user interface (no CLI needed for end users)
- Uses native Windows **RoboCopy** for performance and reliability

---

## Backup Modes Explained

### 🔹 Complete

Creates a full mirror of the source into a dated folder.

- Copies all files and folders
- Deletes files in the destination that no longer exist in the source
- Best for full backups

### 🔹 Incremental

Copies only files that are newer than those in the destination.

- Faster than complete
- Uses `/XO` RoboCopy logic

### 🔹 Differential

Copies files that have changed since the last complete backup.

- Requires at least one successful complete backup
- Uses a baseline timestamp

### 🔹 DryRun

Simulates a backup without copying any data.

- Shows what would be copied
- Safe for testing

---

## Folder Structure (after installation)

```
C:\Users\<User>\BackupTools\
│
├─ Backup.exe
├─ BackupGUI.exe
├─ DiskCopy.ps1
└─ logs\
   └─ DiskCopy_dd-MM-yyyy.log
```

Each user gets their own `logs` folder, making the tool multi-user safe.

---

## Installation

### Using `install.ps1` (Recommended)

Download `install.ps1` :

```powershell
pwsh -NoProfile -Command `
  "iwr https://raw.githubusercontent.com/MilkCoder26/backupTools-powershell/main/install.ps1 -UseBasicParsing | iex"
```

**What the installer does:**

- Creates `BackupTools` in your user profile
- Creates the `logs` folder
- Downloads all required files from GitHub
- Adds `BackupTools` to your user PATH

> ℹ️ **Note:** Restart PowerShell or log out/in after installation to use PATH commands.

---

## Usage

### Graphical Interface (Recommended for end users)

1. Double-click `Backup.exe`
2. Select:
   - Source path (e.g. `E:\`)
   - Destination path (e.g. `D:\`)
   - Backup type
3. Click **Start Backup**
4. A console window opens to show real-time progress
5. A confirmation appears when the backup finishes

### Command Line (Advanced users)

You can also run backups directly:

```powershell
DiskCopy -SourcePath "E:\" -DestinationRoot "D:\" -Mode Complete
```

**Available modes:**

- `Complete`
- `Incremental`
- `Differential`
- `DryRun`

---

## Logs

Logs are stored per user:

```
%USERPROFILE%\BackupTools\logs
```

Each backup creates a dated log file:

```
DiskCopy_dd-MM-yyyy.log
```

---

## Permissions & Notes

- RoboCopy automatically skips protected system folders
- Antivirus software may flag unsigned executables (false positives)

---

## Typical Use Cases

- Personal computer disk backup
- External drive synchronization
- One-click backup for non-technical users
- Pre-migration disk copy
- Backup validation using dry-run mode

---

## Technology Used

- **PowerShell**
- **Windows Forms** (WinForms)
- **RoboCopy** (Windows native)
- **GitHub** for distribution

---

## 📄 License

This project is provided as-is.  
You are free to use, modify, and distribute it according to your needs.

---

## 🤝 Contributing

Contributions, issues, and suggestions are welcome.  
Please open an issue or submit a pull request.

---

**If you want, next I can:**

- Add screenshots section
- Add FAQ / Troubleshooting
- Write a security note
- Create a `CHANGELOG.md`

Just tell me 👍
