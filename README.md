# SAM Modifier Helper

A small Bash utility for **authorized Windows account recovery and offline troubleshooting from a Linux live environment**.

The script automates the repetitive part of locating a Windows installation: it scans local partitions, identifies NTFS volumes, reuses existing mounts when possible, mounts candidate partitions when needed, checks for the Windows SAM hive, and moves you directly into `Windows/System32/config` when it finds one.

> Use this only on systems you own or are explicitly authorized to administer.

## What the script actually does

`SAM_modifier` performs the following workflow:

1. Requires root privileges.
2. Scans common SATA/SCSI and NVMe partition paths under `/dev`.
3. Skips devices that are clearly non-NTFS when `blkid` can identify the filesystem.
4. Reuses an existing mountpoint if the partition is already mounted.
5. Otherwise creates a temporary mountpoint such as `/mnt/win1`.
6. Attempts to mount the NTFS partition read-only using `ntfs-3g` when available, otherwise the kernel NTFS mount path.
7. Looks for:

   ```text
   Windows/System32/config/SAM
   ```

8. If the SAM hive is found, changes into the Windows configuration directory.
9. Depending on how the partition was discovered, it either:
   - launches `chntpw -i SAM`, or
   - drops you into a shell inside the config directory.
10. Cleans up temporary mounts created by the script when it exits normally.

## Important behavior and limitation

The current script mounts partitions it discovers itself using **read-only** options.

That means the script is very useful for locating the correct Windows installation and reaching the SAM hive safely, but a SAM modification cannot be written back through a mount that the script created in read-only mode.

If the Windows partition was already mounted before the script started, the script reuses that mount and preserves its existing mount state. In that branch it may launch `chntpw` directly.

So despite the repository/script name, the script itself is primarily a **SAM locator and recovery helper**. Whether an actual password reset or SAM edit can be committed depends on the mount state and the tool being used.

## Requirements

Required or commonly used commands:

- Bash
- `blkid`
- `findmnt`
- `mount`
- `umount`
- `mountpoint`
- `ntfs-3g` — recommended for NTFS handling
- `chntpw` — required for the interactive SAM editor path
- `lsof` — optional, used only for diagnostics when a device is busy

### Arch Linux

```bash
sudo pacman -S ntfs-3g chntpw lsof
```

`util-linux` normally provides utilities such as `blkid`, `findmnt`, `mount`, and `mountpoint`.

## Usage

Make the script executable:

```bash
chmod +x SAM_modifier
```

Run it as root:

```bash
sudo ./SAM_modifier
```

The script will scan candidate partitions and print what it is doing as it goes.

Typical outcomes include:

- SAM hive found
- partition already mounted
- partition is not NTFS
- Windows partition is hibernated or affected by Fast Startup
- possible BitLocker/encrypted volume
- device is already busy
- no Windows SAM hive detected

## When to use it

This script is appropriate when:

- you are recovering access to your own Windows machine;
- you are servicing a system you are authorized to administer;
- you booted a Linux live environment and want to locate the offline Windows SAM hive quickly;
- you want to avoid manually identifying the Windows partition, mounting each NTFS volume, and navigating to the registry hive directory;
- you are troubleshooting whether the Windows installation is accessible from Linux at all.

## When it will not work

The script will not bypass storage encryption or Windows filesystem safety protections.

Common blockers include:

### BitLocker

If the Windows volume is BitLocker-encrypted and not already unlocked, the SAM hive will not be directly accessible as a normal NTFS filesystem.

### Hibernation / Fast Startup

Windows may leave the NTFS filesystem in an unsafe state after hibernation or Fast Startup. `ntfs-3g` can refuse to mount such a volume to avoid filesystem damage.

The safest fix is to boot Windows, disable Fast Startup or hibernation, and perform a full shutdown before trying again.

For example, from an elevated Windows terminal:

```cmd
powercfg /h off
```

### RAID, dynamic disks, unusual storage layouts

The script only scans common `/dev/sd*` and `/dev/nvme*n*` partition layouts. Windows installations stored behind RAID, Storage Spaces, LVM-like abstractions, unusual controllers, or other device-mapper layers may not be detected automatically.

### Non-NTFS Windows layouts

The script is specifically built around locating a normal NTFS Windows installation containing the standard SAM path.

## What is the SAM hive?

Windows stores local account information inside registry hive files under:

```text
C:\Windows\System32\config\
```

The `SAM` hive contains data associated with local Windows accounts. Windows normally keeps these registry hives locked while the operating system is running, which is why offline recovery workflows often operate from another environment such as a Linux live system or Windows recovery media.

This script does not parse the SAM format itself. It only locates the hive and hands control to other tools or to an interactive shell.

## Safety notes

Editing offline Windows registry hives is inherently risky.

Before making changes:

- verify that you are working on the correct Windows installation;
- keep a backup of important data;
- avoid writing to a filesystem that Windows left in a hibernated or unsafe state;
- prefer official recovery methods when they are available;
- understand that changing local account credentials can affect access to data protected by Windows account-dependent encryption mechanisms.

The script deliberately prefers read-only mounting for partitions it mounts itself. That reduces the chance of accidental filesystem modification while searching for the SAM hive.

## Error handling

The script attempts to distinguish several common failures and provide useful diagnostics:

- `Device or resource busy`
- existing mounts
- hibernated / unsafe NTFS state
- possible BitLocker or encrypted partitions
- already-opened devices
- missing SAM hive

When a temporary mount was created by the script, cleanup logic attempts to unmount and remove that temporary mountpoint on exit.

## Example high-level flow

```text
Linux live environment
        |
        v
Run SAM_modifier as root
        |
        v
Scan /dev/sd* and /dev/nvme*n*
        |
        v
Identify/reuse NTFS partition
        |
        v
Look for Windows/System32/config/SAM
        |
   +----+----+
   |         |
  No        Yes
   |         |
continue    cd into config directory
scanning     |
             +--> launch chntpw in one path
             |
             +--> or open an interactive shell
```

## Scope

This project is intentionally small. It does not attempt to:

- defeat BitLocker;
- recover Microsoft account credentials;
- crack passwords;
- parse SAM structures itself;
- automatically force-write to Windows partitions;
- modify Windows filesystems that are unsafe to mount.

Its purpose is to reduce the manual Linux commands normally required to locate an offline Windows SAM hive.

## Disclaimer

This project is intended for legitimate system administration, recovery, education, and troubleshooting on systems you own or have explicit permission to service. You are responsible for complying with applicable laws, policies, and organizational rules.
