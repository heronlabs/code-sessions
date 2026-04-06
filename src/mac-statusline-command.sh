#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')


# Git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# 1) Branch segment — first, prominent in cyan
git_segment=""
if [ -n "$git_branch" ]; then
  git_segment="\033[0;36m $git_branch\033[0m"
fi

# 2) Token usage as progress bar
token_info=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")

  # Color based on usage
  if [ "$used_int" -lt 50 ]; then
    bar_color="\033[0;32m"  # green
  elif [ "$used_int" -lt 80 ]; then
    bar_color="\033[0;33m"  # yellow
  else
    bar_color="\033[0;31m"  # red
  fi

  # Build 10-char progress bar
  bar_width=10
  filled=$(( (used_int * bar_width + 99) / 100 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  empty=$((bar_width - filled))

  bar=""
  i=0; while [ $i -lt $filled ]; do bar="${bar}▓"; i=$((i+1)); done
  i=0; while [ $i -lt $empty ];  do bar="${bar}░"; i=$((i+1)); done

  token_info=" \033[0;90m│\033[0m ${bar_color}Ctx ${bar} ${used_int}%\033[0m"
elif [ -n "$total_input" ] && [ -n "$total_output" ]; then
  total_tokens=$((total_input + total_output))
  token_info=" \033[0;90m│\033[0m Ctx: ${total_tokens}"
fi

# 3) Usage limits — show "X% left" for most constrained window
USAGE_CACHE="/tmp/claude_usage_cache.json"
CACHE_TTL=300
usage_segment=""

# Refresh cache in background if stale; always read from cache if present
if [ -f "$USAGE_CACHE" ]; then
  cache_mtime=$(stat -f %m "$USAGE_CACHE" 2>/dev/null)
  now=$(date +%s)
  age=$((now - cache_mtime))
  if [ "$age" -ge "$CACHE_TTL" ]; then
    (
      raw_creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
      token=$(echo "$raw_creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      if [ -n "$token" ]; then
        curl -s "https://api.anthropic.com/api/oauth/usage" \
          -H "Authorization: Bearer $token" \
          -H "anthropic-beta: oauth-2025-04-20" > "$USAGE_CACHE" 2>/dev/null
      fi
    ) &
  fi
  usage_data=$(cat "$USAGE_CACHE")
else
  raw_creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  token=$(echo "$raw_creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [ -n "$token" ]; then
    usage_data=$(curl -s "https://api.anthropic.com/api/oauth/usage" \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)
    [ -n "$usage_data" ] && echo "$usage_data" > "$USAGE_CACHE"
  fi
fi

if [ -n "$usage_data" ]; then
  five_hr=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  seven_day=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
  if [ -n "$five_hr" ] && [ -n "$seven_day" ]; then
    five_hr_int=$(printf "%.0f" "$five_hr")
    seven_day_int=$(printf "%.0f" "$seven_day")
    five_hr_left=$((100 - five_hr_int))
    seven_day_left=$((100 - seven_day_int))

    # Show the most constrained window
    if [ "$five_hr_left" -lt "$seven_day_left" ]; then
      limit_left=$five_hr_left
      limit_label="5h"
    else
      limit_left=$seven_day_left
      limit_label="7d"
    fi

    # Color based on remaining
    if [ "$limit_left" -gt 50 ]; then
      limit_color="\033[0;32m"  # green
    elif [ "$limit_left" -gt 20 ]; then
      limit_color="\033[0;33m"  # yellow
    else
      limit_color="\033[0;31m"  # red
    fi

    usage_segment=" \033[0;90m│\033[0m ${limit_color}${limit_left}% left (${limit_label})\033[0m"
  fi
fi

# 4) Session uptime
uptime_segment=""
START_FILE="/tmp/claude_session_start"
if [ ! -f "$START_FILE" ]; then
  date +%s > "$START_FILE"
fi
elapsed=$(( $(date +%s) - $(cat "$START_FILE") ))
uh=$((elapsed / 3600))
um=$(( (elapsed % 3600) / 60 ))
uptime_segment=" \033[0;90m│\033[0m \033[0;33m⏱ ${uh}h $(printf '%02d' $um)m\033[0m"

# 5) Model name — short, dimmed, at the end
model_segment=""
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed 's/Claude //' | sed 's/ (.*//')
  model_segment=" \033[0;90m│ ${short_model}\033[0m"
fi

# 6) Claude Code version — dimmed
claude_ver=$(claude --version 2>/dev/null | awk '{print $1}')
ver_segment=""
if [ -n "$claude_ver" ]; then
  ver_segment=" \033[0;90m│ v${claude_ver}\033[0m"
fi

# Build the status line: branch | ctx bar | limits | uptime | model | version
printf "%b%b%b%b%b%b\n" "$git_segment" "$token_info" "$usage_segment" "$uptime_segment" "$model_segment" "$ver_segment"
