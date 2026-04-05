# Claude Session Setup — Ubuntu

Complete guide to replicate the Mac-based Claude Code session environment on Ubuntu, including Zsh, Powerlevel10k, tmux, Tailscale, and the session scripts.

---

## 1. Update your system

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Install Zsh

```bash
sudo apt install -y zsh
```

Set Zsh as your default shell:

```bash
chsh -s $(which zsh)
```

Log out and log back in (or reboot) for the change to take effect. Verify:

```bash
echo $SHELL
# Should output: /usr/bin/zsh
```

---

## 3. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

When prompted to change your default shell, answer **Yes**.

---

## 4. Install Powerlevel10k

### 4.1 Install a Nerd Font

p10k requires a patched font. Install **MesloLGS NF** (the recommended font):

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv
```

Then set **MesloLGS NF** as your terminal font:

- **GNOME Terminal**: Preferences → Profile → Custom font → `MesloLGS NF Regular`
- **Konsole**: Settings → Edit Current Profile → Appearance → Font → `MesloLGS NF`
- **Terminator**: Preferences → Profiles → General → Font → `MesloLGS NF`
- **Alacritty**: Set `font.normal.family: "MesloLGS NF"` in `~/.config/alacritty/alacritty.toml`
- **Windows Terminal (WSL)**: Settings → Profile → Appearance → Font face → `MesloLGS NF`

### 4.2 Install p10k theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Edit `~/.zshrc` and set the theme:

```bash
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
```

Restart your terminal or run `exec zsh`. The p10k configuration wizard will start automatically. Walk through it to pick your preferred prompt style.

To reconfigure later:

```bash
p10k configure
```

---

## 5. Install tmux

```bash
sudo apt install -y tmux
```

Verify:

```bash
tmux -V
# e.g. tmux 3.3a
```

---

## 6. Install Claude Code CLI

Install Node.js (required by Claude Code):

```bash
# Install Node.js 20 LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Install Claude Code globally:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

Run `claude` once to authenticate and complete initial setup.

---

## 7. Install Tailscale (remote SSH access)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Start and authenticate:

```bash
sudo tailscale up
```

Follow the URL in the terminal to authenticate. Confirm your machine appears at https://login.tailscale.com/admin/machines

Check your Tailscale IP:

```bash
tailscale status
```

Your SSH address from any device will be:

```
your-ubuntu-hostname.tail12345.ts.net
```

---

## 8. Enable SSH on Ubuntu

```bash
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

Verify SSH works locally:

```bash
ssh localhost
# Should connect. Type `exit` to leave.
```

---

## 9. Set up the project directory

Create the work directory structure (matching the Mac setup):

```bash
mkdir -p ~/Workfolder
cd ~/Workfolder
git clone https://github.com/lucaslacerdacl/code-sessions.git
```

Create your working project folder:

```bash
mkdir -p ~/Workfolder/workloads
```

---

## 10. Create symbolic links

Link the **Ubuntu version** of the session script and the shared keepalive script:

```bash
ln -sf ~/Workfolder/code-sessions/src/ubuntu-claude-session.sh ~/.claude-session.sh
ln -sf ~/Workfolder/code-sessions/src/claude-keepalive.sh ~/.claude-keepalive.sh
chmod +x ~/Workfolder/code-sessions/src/*.sh
```

Verify:

```bash
ls -la ~/.claude-session.sh ~/.claude-keepalive.sh
```

You should see arrows pointing to the scripts under `~/Workfolder/code-sessions/src/`.

---

## 11. Copy CLAUDE.md to your workdir

```bash
cp ~/Workfolder/code-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

> This is a copy, not a symlink — Claude reads it from the workdir at runtime.
> Re-run this step whenever you update CLAUDE.md.

---

## 12. Add aliases to your zshrc

Open `~/.zshrc` and add the alias block from [README.md — Shell Aliases](README.md#shell-aliases-all-platforms).

Reload:

```bash
source ~/.zshrc
```

---

## 13. Verify everything works

```bash
start-s workloads
```

You'll see a full-screen tmux session with Claude running inside `~/Workfolder/workloads`.

```bash
# Detach from tmux (keeps everything running):
# Press Ctrl+B, then D

# Resume from another terminal or after SSH:
resume-s workloads

# Stop everything cleanly:
stop-s workloads
```

---

## 14. Set up Termius on your phone (remote fallback)

1. Download **Termius** from the App Store or Google Play
2. Create a new host:
   - **Hostname:** your Tailscale MagicDNS address (e.g. `your-ubuntu-hostname.tail12345.ts.net`)
   - **Username:** your Ubuntu username (run `whoami` to confirm)
   - **Auth:** password or SSH key
3. Connect — you'll land in your Ubuntu shell
4. To reattach to your Claude session: `tmux attach -t claude-workloads`
5. To list all running sessions: `tmux ls`

### Optional: SSH key auth (no password needed from phone)

```bash
# On your Ubuntu machine, generate a key if you don't have one:
ssh-keygen -t ed25519 -C "termius-mobile"

# Add the public key to authorized_keys:
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Then in Termius, import the private key (`~/.ssh/id_ed25519`) under **Keychain**.

---

## Key differences from the Mac setup

| Feature | Mac | Ubuntu |
|---|---|---|
| Sleep prevention | `caffeinate -dims` | `systemd-inhibit` (blocks idle, sleep, lid switch) |
| Memory in status bar | `memory_pressure` | `free -m` with awk |
| Package manager | Homebrew (`brew`) | APT (`apt`) |
| SSH server | System Settings toggle | `openssh-server` package |
| Tailscale install | `brew install --cask tailscale` | `curl` install script |
| Shell change | Already Zsh on modern macOS | `chsh -s $(which zsh)` |
| Session script | `claude-session.sh` | `ubuntu-claude-session.sh` |

---

## How everything fits together

| Layer | What it does |
|---|---|
| `systemd-inhibit` | Prevents idle sleep and lid-switch suspend |
| `tmux` | Keeps all processes running detached from any terminal |
| `keepalive` (background) | Pings Anthropic API every 55s to prevent connection drops |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| `Tailscale` | Private network between your devices — no port forwarding needed |
| `SSH + Termius` | Fallback terminal from your phone if `claude remote` stops working |

### Remote access paths

```
Primary:   claude remote (from Claude app / phone)
Fallback:  Tailscale SSH → Termius → tmux attach -t claude-workloads → manual control
```

> No systemd service needed. After a full reboot, run `start-s workloads` again.
> To update any script, edit it in `~/Workfolder/code-sessions/src/` — no re-linking needed.
