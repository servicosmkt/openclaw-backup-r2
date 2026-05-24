# OpenClaw Backup → Cloudflare R2 (via restic)

> **Never lose your OpenClaw agents and config again.**

A complete, encrypted, off-site backup for your [OpenClaw](https://openclaw.ai) setup — pushed to Cloudflare R2 with [restic](https://restic.net). Set it once, and a daily job keeps a versioned, encrypted copy of **everything** in the cloud. If your machine dies, an update breaks your config, or you just want to move to a new PC, you restore the whole thing in minutes.

---

## Why this exists

OpenClaw is powerful, but its config is easy to break. One unlucky `openclaw doctor --fix` can wipe your agents and corrupt `openclaw.json` — and suddenly you're rebuilding credentials, agents, routing rules and channel bindings by hand. That's hours of work to get back to where you were.

This project was born from exactly that pain. The fix is simple: **automated, complete, off-site backups** that you can restore from in minutes — on any machine.

OpenClaw already keeps a local `.bak` of `openclaw.json`, but that only covers the config file. It does **not** cover your credentials, agents, workspace or cron jobs — and it lives on the same disk that might fail. This tool covers all of it, encrypted and off-site.

| | OpenClaw's built-in `.bak` | **This project** |
|---|:---:|:---:|
| `openclaw.json` config | ✅ | ✅ |
| Credentials / auth profiles | ❌ | ✅ |
| Agents & workspaces | ❌ | ✅ |
| Cron / scheduled tasks | ❌ | ✅ |
| Off-site (survives disk failure) | ❌ | ✅ |
| Encrypted | ❌ | ✅ |
| Automatic daily + retention | ❌ | ✅ |
| Restore on a brand-new PC | ❌ | ✅ |

---

## When it saves you

- 💥 **A config change broke everything** → restore yesterday's working state in minutes.
- 🖥️ **Your PC died / you got a new one** → run the portable restore on the new machine, pull from R2, done.
- 🔄 **You're migrating setups** → carry the whole OpenClaw state across machines.
- 😌 **Peace of mind** → a fresh encrypted snapshot lands in the cloud every day, automatically.

---

## How it works

```
openclaw backup create --verify   →   <date>-openclaw-backup.tar.gz
                                            │
                                   restic backup (dedupe + client-side encryption)
                                            │
                                            ▼
                                   Cloudflare R2  (only sees encrypted blobs)
                                            │
                                   restic forget --prune  (retention)
```

1. Generates OpenClaw's **native verified backup** (`openclaw backup create --verify`) — config, credentials, agents, workspace, cron.
2. **restic** encrypts and deduplicates it **on your machine**, then uploads to R2. The cloud never sees plaintext.
3. Applies **retention**: keeps 7 daily + 4 weekly + 6 monthly snapshots automatically.

### Why restic + R2?

- **End-to-end encryption** — data is encrypted *before* it leaves your machine. R2 only stores ciphertext.
- **Deduplication** — only changed chunks are uploaded, so daily backups are tiny and fast.
- **Cheap & off-site** — Cloudflare R2 has a generous free tier and **no egress fees**, so restores cost nothing.
- **Portable** — restic is a single binary; restore from any computer.

---

## Requirements

- Windows + PowerShell
- [OpenClaw](https://openclaw.ai) installed
- [restic](https://restic.net/#installation) (on your PATH or in `.\restic\restic.exe`)
- A [Cloudflare R2](https://developers.cloudflare.com/r2/) bucket + an S3 API token

---

## Setup

1. **Copy `.env.example` to `.env`** and fill it in:
   ```ini
   RESTIC_REPOSITORY=https://<accountid>.r2.cloudflarestorage.com/<your-bucket>
   AWS_ACCESS_KEY_ID=...
   AWS_SECRET_ACCESS_KEY=...
   ```
2. **Create `.restic-pass`** with a strong password. This encrypts your backups — **store it somewhere safe; without it there is no restore.**
3. **Initialize the restic repo once:**
   ```powershell
   restic init
   ```

---

## Usage

**Back up now:**
```powershell
.\backup.ps1
```
…or just double-click `backup-agora.bat`.

**Test a restore (without touching your live install):**
```powershell
.\test-restore.ps1
```
Downloads the latest backup, extracts it, and validates it with `openclaw backup verify`. The restored folder is left intact for you to inspect.

**Real restore (on any PC):**
Copy the `portable\` folder (with `restic\restic.exe`, `.env`, and `.restic-pass`) to the new machine and run:
```powershell
.\portable\restore-portable.ps1
```
It pulls the latest backup from R2 and installs it to `%USERPROFILE%\.openclaw`, **preserving** your current `.openclaw` as `.openclaw.backup-<date>` before overwriting.

---

## Automatic daily backup (Windows Task Scheduler)

```powershell
$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\path\to\backup.ps1"'
$trigger  = New-ScheduledTaskTrigger -Daily -At 12:00
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName "OpenClaw Backup" -Action $action -Trigger $trigger -Settings $settings -Description "Daily OpenClaw backup to R2"
```
`-StartWhenAvailable` runs the backup as soon as the PC boots if it was off at the scheduled time, so you never miss a day.

---

## Security

- `.env` and `.restic-pass` are **never** committed (blocked by `.gitignore`). The repo only ships `.env.example` templates with no real values.
- Backups are encrypted by restic **before** upload — R2 only ever stores ciphertext.
- Restore-test folders contain restored sensitive data and are also git-ignored.
- **Keep your `.restic-pass` safe and backed up separately.** It is the only key to your encrypted backups.

---

## Contributing

Issues and PRs welcome! This started as a personal fix and is shared so the OpenClaw community doesn't have to relive the "I lost all my agents" nightmare. If you adapt it for Linux/macOS or other S3-compatible storage (Backblaze B2, AWS S3, MinIO), please open a PR.

## License

MIT — use it, fork it, improve it.
