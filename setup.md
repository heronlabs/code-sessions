# Claude Session Setup — Manual Steps

Follow these steps in order. Everything here requires your confirmation before running.

---

## 1. Install dependencies

### Tailscale (for remote SSH access as fallback)
```bash
brew install --cask tailscale
```

Then open Tailscale from Applications and sign in with your account.
After signing in, confirm your Mac appears at https://login.tailscale.com/admin/machines

---

## 2. Enable SSH on your Mac

Go to: **System Settings → General → Sharing → Remote Login** → toggle ON

Verify SSH works locally:
```bash
ssh localhost
# Should connect. Type `exit` to leave.
```

---

## 3. Start Tailscale and note your MagicDNS hostname

```bash
tailscale status
```

You'll see output like:
```
100.x.x.x   your-macbook-name   self    macOS   -
```

Your SSH address from any device will be:
```
your-macbook-name.tail12345.ts.net
```

Or use the IP directly: `100.x.x.x`

`lucass-macbook-pro.tail12345.ts.net`

---

## 4. Create symbolic links

Instead of copying files, link them so `~/Workfolder/claude-sessions/src/` stays the single source of truth.
Edit the scripts there and the links pick up changes automatically.

```bash
ln -sf ~/Workfolder/claude-sessions/src/claude-session.sh ~/.claude-session.sh
ln -sf ~/Workfolder/claude-sessions/src/claude-keepalive.sh ~/.claude-keepalive.sh
chmod +x ~/Workfolder/claude-sessions/src/*.sh
```

Verify the links are correct:
```bash
ls -la ~/.claude-session.sh ~/.claude-keepalive.sh
```

You should see `-> ~/Workfolder/claude-sessions/src/...` next to each file.

---

## 5. Copy CLAUDE.md to your workdir

```bash
cp ~/Workfolder/claude-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

> This one is a copy, not a symlink — Claude reads it from the workdir at runtime.
> Re-run this step whenever you update CLAUDE.md.

---

## 6. Add aliases to your zshrc

Open `~/.zshrc` and add this block manually:

```zsh
# Claude session management
alias wake-up="~/.claude-session.sh"

claude-resume() {
  local name="${1:-default}"
  tmux attach -t "claude-$(echo "$name" | tr '[:upper:]' '[:lower:]')"
}

claude-stop() {
  local name="${1:-default}"
  local session="claude-$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  tmux kill-session -t "$session" 2>/dev/null
  if [ -f /tmp/claude-caffeinate.pid ]; then
    kill "$(cat /tmp/claude-caffeinate.pid)" 2>/dev/null
    rm /tmp/claude-caffeinate.pid
  fi
  echo "Session ${session} stopped."
}

alias claude-remote-log="tail -f /tmp/claude-remote.log"
```

Then reload:
```bash
source ~/.zshrc
```

---

## 7. Verify everything works

```bash
wake-up steve
```

Once inside tmux you'll see 2 panes:
- Left (75%): your interactive Claude session
- Right (25%): keepalive ping loop

```bash
# Detach from tmux (keeps everything running):
# Press Ctrl+B, then D

# Resume from another terminal or after opening lid:
claude-resume steve

# Stop everything cleanly:
claude-stop steve
```

---

## 8. Set up Termius on your iPhone (remote fallback)

1. Download **Termius** from the App Store (free tier is enough)
2. Create a new host:
   - **Hostname:** your Tailscale MagicDNS address (e.g. `your-macbook-name.tail12345.ts.net`)
   - **Username:** your Mac username (run `whoami` on your Mac to confirm)
   - **Auth:** use your Mac login password, or set up SSH key (see below)
3. Connect — you'll land in your Mac's shell
4. To reattach to your Claude session: `tmux attach -t claude-steve`
5. To list all running sessions: `tmux ls`

### Optional: SSH key auth (no password needed from phone)

```bash
# On your Mac, generate a key if you don't have one:
ssh-keygen -t ed25519 -C "termius-mobile"

# Copy the public key to authorized_keys:
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Then in Termius, import the private key (`~/.ssh/id_ed25519`) under **Keychain**.

---

## How everything fits together

| Layer | What it does |
|---|---|
| `caffeinate -dims` | Prevents display sleep, idle sleep, and disk sleep — lid close works |
| `tmux` | Keeps all processes running detached from any terminal |
| `keepalive` pane (25%) | Pings Anthropic API every 55s to prevent connection drops |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| `Tailscale` | Private network between your devices — no port forwarding needed |
| `SSH + Termius` | Fallback terminal from your iPhone if `claude remote` stops working |

### Remote access paths

```
Primary:   claude remote (from Claude app / iPhone)
Fallback:  Tailscale SSH → Termius → tmux attach -t claude-steve → manual control
```

> No LaunchAgent needed. After a full reboot, run `wake-up steve` again.
> To update any script, edit it in `~/Workfolder/claude-sessions/src/` — no re-linking needed.
