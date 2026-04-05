# Claude Session Setup — Windows (WSL2)

Complete guide to set up persistent Claude Code sessions on Windows using WSL2 (Windows Subsystem for Linux). This gives you a full Linux environment inside Windows with Zsh, Powerlevel10k, and tmux.

---

## 1. Install WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This installs WSL2 with Ubuntu by default. Restart your computer when prompted.

After reboot, Ubuntu will open and ask you to create a username and password.

Verify WSL2 is running:

```powershell
wsl --list --verbose
```

You should see Ubuntu with VERSION 2.

---

## 2. Install Windows Terminal (recommended)

Download from the **Microsoft Store** or:

```powershell
winget install Microsoft.WindowsTerminal
```

Set Ubuntu (WSL) as your default profile in Windows Terminal settings.

---

## 3. Update your WSL Ubuntu

Inside WSL:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 4. Install Zsh

```bash
sudo apt install -y zsh
chsh -s $(which zsh)
```

Close and reopen your terminal for the change to take effect. Verify:

```bash
echo $SHELL
# Should output: /usr/bin/zsh
```

---

## 5. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## 6. Install Powerlevel10k

### 6.1 Install a Nerd Font

Download and install **MesloLGS NF** on **Windows** (not inside WSL):

1. Download all four files from https://github.com/romkatv/powerlevel10k#manual-font-installation
2. Open each `.ttf` file and click **Install**

Then set the font in your terminal:

- **Windows Terminal**: Settings → Ubuntu Profile → Appearance → Font face → `MesloLGS NF`
- **VS Code terminal**: Add `"terminal.integrated.fontFamily": "MesloLGS NF"` to settings.json

### 6.2 Install p10k theme

Inside WSL:

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Set the theme in `~/.zshrc`:

```bash
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
```

Restart the terminal. The p10k wizard will launch. To reconfigure later:

```bash
p10k configure
```

---

## 7. Install tmux

```bash
sudo apt install -y tmux
```

---

## 8. Install Claude Code CLI

```bash
# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Claude Code
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

Run `claude` once to authenticate.

---

## 9. Install Tailscale

### On the Windows host

Download and install Tailscale from https://tailscale.com/download/windows

Sign in and confirm your machine appears at https://login.tailscale.com/admin/machines

### Inside WSL (optional, for direct WSL SSH)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

> **Note:** For most setups, installing Tailscale on the Windows host is sufficient.
> SSH into the Windows host, then run `wsl` to enter your Linux environment.

---

## 10. Enable SSH

### Option A: Windows OpenSSH (recommended)

Open **PowerShell as Administrator**:

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable the service
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

When you SSH into Windows, you'll land in PowerShell. Then run `wsl` to enter your Linux environment and reattach to tmux.

### Option B: SSH inside WSL (requires systemd)

If your WSL2 has systemd enabled (Windows 11 22H2+):

```bash
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## 11. Set up the project directory

```bash
mkdir -p ~/Workfolder
cd ~/Workfolder
git clone https://github.com/lucaslacerdacl/code-sessions.git
mkdir -p ~/Workfolder/workloads
```

---

## 12. Create symbolic links

```bash
ln -sf ~/Workfolder/code-sessions/src/windows-claude-session.sh ~/.claude-session.sh
ln -sf ~/Workfolder/code-sessions/src/claude-keepalive.sh ~/.claude-keepalive.sh
chmod +x ~/Workfolder/code-sessions/src/*.sh
```

Verify:

```bash
ls -la ~/.claude-session.sh ~/.claude-keepalive.sh
```

---

## 13. Copy CLAUDE.md to your workdir

```bash
cp ~/Workfolder/code-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

---

## 14. Add aliases to your zshrc

Open `~/.zshrc` and add the alias block from [README.md — Shell Aliases](README.md#shell-aliases-all-platforms).

Reload:

```bash
source ~/.zshrc
```

---

## 15. Prevent Windows from sleeping

The session script calls `powercfg` to disable sleep while a session is active. You can also set this manually:

**PowerShell (Admin):**

```powershell
# Disable sleep on AC power
powercfg /change standby-timeout-ac 0

# Re-enable sleep when done (e.g., 30 minutes)
powercfg /change standby-timeout-ac 30
```

Or go to: **Settings → System → Power & battery → Screen and sleep** → set "Sleep" to **Never** while running sessions.

---

## 16. Verify everything works

```bash
start-s workloads
```

```bash
# Detach: Ctrl+B, then D
# Resume:
resume-s workloads

# Stop:
stop-s workloads
```

---

## 17. Remote access from your phone

1. Install **Termius** on your phone
2. Create a host with your Tailscale address (Windows host)
3. Connect via SSH → run `wsl` → `tmux attach -t claude-workloads`

---

## Windows-specific details

| Feature | Implementation |
|---|---|
| Linux environment | WSL2 with Ubuntu |
| Sleep prevention | `powercfg` via PowerShell (Windows host) |
| Memory in status bar | `free -m` (inside WSL) |
| SSH access | Windows OpenSSH → `wsl` command |
| Font installation | On Windows host (not inside WSL) |
| Tailscale | On Windows host (SSH into Windows, then `wsl`) |

---

## WSL2 Tips

- **Access Windows files from WSL:** `/mnt/c/Users/<username>/`
- **Access WSL files from Windows:** `\\wsl$\Ubuntu\home\<username>\`
- **Keep WSL running after closing terminal:** WSL stays alive as long as processes are running inside it
- **If WSL shuts down unexpectedly:** Run `wsl` from PowerShell to restart, then `resume-s <project>`
