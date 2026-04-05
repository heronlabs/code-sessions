# Claude Session Setup — macOS

Complete guide to set up persistent Claude Code sessions on macOS.

---

## 1. Install Tailscale (remote SSH access)

```bash
brew install --cask tailscale
```

Open Tailscale from Applications and sign in with your account.
Confirm your Mac appears at https://login.tailscale.com/admin/machines

---

## 2. Enable SSH on your Mac

Go to: **System Settings → General → Sharing → Remote Login** → toggle ON

Verify SSH works locally:

```bash
ssh localhost
# Should connect. Type `exit` to leave.
```

---

## 3. Get your Tailscale address

```bash
tailscale status
```

Output:

```
100.x.x.x   your-macbook-name   self    macOS   -
```

Your SSH address from any device:

```
your-macbook-name.tail12345.ts.net
```

---

## 4. Clone the repository

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

## 5. Create symbolic links

```bash
ln -sf ~/Workfolder/code-sessions/src/claude-session.sh ~/.claude-session.sh
ln -sf ~/Workfolder/code-sessions/src/claude-keepalive.sh ~/.claude-keepalive.sh
chmod +x ~/Workfolder/code-sessions/src/*.sh
```

Verify:

```bash
ls -la ~/.claude-session.sh ~/.claude-keepalive.sh
```

You should see arrows pointing to `~/Workfolder/code-sessions/src/...`.

---

## 6. Copy CLAUDE.md to your workdir

```bash
cp ~/Workfolder/code-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

> This is a copy, not a symlink — Claude reads it from the workdir at runtime.
> Re-run this step whenever you update CLAUDE.md.

---

## 7. Add aliases to your zshrc

Open `~/.zshrc` and add the alias block from [README.md — Shell Aliases](README.md#shell-aliases-all-platforms).

Reload:

```bash
source ~/.zshrc
```

---

## 8. Verify everything works

```bash
start-s workloads
```

You'll see a full-screen tmux session with Claude running inside `~/Workfolder/workloads`.

```bash
# Detach from tmux (keeps everything running):
# Press Ctrl+B, then D

# Resume from another terminal or after opening lid:
resume-s workloads

# Stop everything cleanly:
stop-s workloads
```

---

## 9. Set up Termius on your iPhone (remote fallback)

1. Download **Termius** from the App Store
2. Create a new host:
   - **Hostname:** your Tailscale MagicDNS address (e.g. `your-macbook-name.tail12345.ts.net`)
   - **Username:** your Mac username (run `whoami` to confirm)
   - **Auth:** password or SSH key
3. Connect and reattach: `tmux attach -t claude-workloads`
4. List all sessions: `tmux ls`

### Optional: SSH key auth

```bash
ssh-keygen -t ed25519 -C "termius-mobile"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Import the private key in Termius under **Keychain**.

---

## macOS-specific details

| Feature | Implementation |
|---|---|
| Sleep prevention | `caffeinate -dims` (prevents display, idle, and disk sleep) |
| Memory in status bar | `memory_pressure` (macOS built-in) |
| Package manager | Homebrew (`brew`) |
| SSH server | System Settings → Remote Login |
| Default shell | Zsh (default on modern macOS) |
