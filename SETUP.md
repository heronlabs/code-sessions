# Claude Session Setup

One guide for **macOS** and **Ubuntu**. Steps that differ are split into two short subsections; everything else is shared.

---

## 1. Install prerequisites

You need: **tmux**, **zsh**, **Node.js**, **Claude Code CLI**, **Tailscale**, and an **SSH server**.

### macOS

```bash
# Homebrew (skip if installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# tmux + node
brew install tmux node

# Claude Code
npm install -g @anthropic-ai/claude-code

# Tailscale (GUI app)
brew install --cask tailscale
```

Enable SSH: **System Settings → General → Sharing → Remote Login → ON**.
Zsh is already the default shell on modern macOS.

### Ubuntu

```bash
sudo apt update && sudo apt upgrade -y

# tmux + zsh + ssh
sudo apt install -y tmux zsh openssh-server

# Make zsh the default shell (log out/in afterwards)
chsh -s "$(which zsh)"

# Node 20 LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Claude Code
npm install -g @anthropic-ai/claude-code

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
```

Enable + start SSH:

```bash
sudo systemctl enable --now ssh
```

> **Optional but recommended on Ubuntu:** Oh My Zsh + Powerlevel10k for a nicer prompt — see [Appendix A](#appendix-a--ubuntu-prompt-omz--p10k).

---

## 2. Authenticate Claude

Run `claude` once and complete the auth flow.

```bash
claude --version
claude
```

---

## 3. Authenticate Tailscale

### macOS

Open Tailscale.app and sign in.

### Ubuntu

```bash
sudo tailscale up --accept-dns=false --accept-routes=false --netfilter-mode=off
sudo tailscale set --accept-dns=false --accept-routes=false --netfilter-mode=off
```

> The flags prevent Tailscale from overriding system DNS / iptables rules, which can break your wired/Wi-Fi internet on Ubuntu.

### Both

Confirm your machine appears at <https://login.tailscale.com/admin/machines>, then check your address:

```bash
tailscale status
```

Your SSH address from any device will look like `your-hostname.tail12345.ts.net`.

---

## 4. Clone this repo

```bash
mkdir -p ~/Workfolder
cd ~/Workfolder
git clone https://github.com/lucaslacerdacl/code-sessions.git

# Create a working folder (this is what you'll pass to start-s)
mkdir -p ~/Workfolder/workloads
```

---

## 5. Link the launcher

```bash
ln -sf ~/Workfolder/code-sessions/src/claude-session.sh ~/.claude-session.sh
chmod +x ~/Workfolder/code-sessions/src/*.sh
```

Verify the symlink:

```bash
ls -la ~/.claude-session.sh
```

---

## 6. Copy `CLAUDE.md` into your workdir

```bash
cp ~/Workfolder/code-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

> This is a copy, not a symlink — Claude reads it from the workdir at runtime. Re-run when you update the source.

---

## 7. Add the aliases

Open `~/.zshrc` and paste the alias block from [README.md → Shell Aliases](README.md#shell-aliases). Then:

```bash
source ~/.zshrc
```

---

## 8. Verify

```bash
start-s workloads
```

You should land in a tmux session with Claude running inside `~/Workfolder/workloads`.

```bash
# Detach (keeps Claude running):       Ctrl+B, then D
resume-s workloads                     # reattach
stop-s workloads                       # kill the session
```

Try a nested path to confirm the worktree-friendly naming:

```bash
mkdir -p ~/Workfolder/workloads/.worktrees/demo
start-s workloads/.worktrees/demo      # session: workloads-demo
```

---

## 9. Termius (mobile fallback)

1. Install **Termius** (App Store / Google Play).
2. New host:
   - **Hostname:** your Tailscale MagicDNS address (e.g. `your-hostname.tail12345.ts.net`)
   - **Username:** result of `whoami`
   - **Auth:** password or SSH key
3. Connect, then `tmux attach -t <session>` (e.g. `tmux attach -t workloads`).
4. List sessions: `tmux ls`.

### Optional: SSH key auth

```bash
ssh-keygen -t ed25519 -C "termius-mobile"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Import the private key in Termius under **Keychain**.

---

## How everything fits together

| Layer | What it does |
|---|---|
| `tmux` | Keeps Claude running detached from any terminal |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| Tailscale | Private network between your devices — no port forwarding |
| SSH + Termius | Fallback terminal from your phone if `claude remote` stops working |

After a reboot, just run `start-s <folder>` again. To update the launcher, edit `~/Workfolder/code-sessions/src/claude-session.sh` — no re-linking needed.

---

## Appendix A — Ubuntu prompt (OMZ + p10k)

Optional, but recommended on Ubuntu since the default Zsh prompt is sparse.

### Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Powerlevel10k

Install a Nerd Font (MesloLGS NF):

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
for f in "Regular" "Bold" "Italic" "Bold%20Italic"; do
  curl -fLO "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${f}.ttf"
done
fc-cache -fv
```

Set **MesloLGS NF** as your terminal font (GNOME Terminal / Konsole / Alacritty / Windows Terminal — wherever applicable).

Install the theme:

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
```

Restart the terminal — the p10k wizard will run. To reconfigure later: `p10k configure`.
