#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Model ---
parts="🤖 $model"

# --- Current directory ---
if [ -n "$cwd" ]; then
  home="$HOME"
  # Convert Windows backslashes to forward slashes
  cwd=$(echo "$cwd" | tr '\\' '/')
  home=$(echo "$home" | tr '\\' '/')
  display_cwd="${cwd/#$home/~}"
  folder_line="📁 $display_cwd"
fi

# --- Git info ---
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
  remote_url=$(git -C "$cwd" --no-optional-locks remote get-url origin 2>/dev/null)
  if [ -n "$remote_url" ]; then
    repo=$(echo "$remote_url" | sed -E 's|.*[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
    git_info="$repo"
    [ -n "$branch" ] && git_info="$git_info ($branch)"
  else
    git_info="${branch:-detached}"
  fi
  parts="$parts │ 🐙 $git_info"
else
  parts="$parts │ 🐙 no git"
fi

# --- Context battery (no ANSI colors - use plain emoji) ---
if [ -n "$remaining" ]; then
  remaining_int=$(printf "%.0f" "$remaining")

  used_int=$(printf "%.0f" "$used")

  # Build 10-char battery bar based on used percentage
  filled=$(( used_int / 10 ))
  empty=$(( 10 - filled ))
  bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty);  do bar="${bar}░"; done

  parts="$parts │ 🔋[$bar] ${used_int}%"
fi

# --- Rate limits ---
rate=""
[ -n "$five" ] && rate="5h:$(printf '%.0f' "$five")%"
[ -n "$week" ] && { [ -n "$rate" ] && rate="$rate "; rate="${rate}7d:$(printf '%.0f' "$week")%"; }
[ -n "$rate" ] && parts="$parts │ ⚡$rate"

# Output: line 1 = model/git/battery/rate, line 2 = folder
if [ -n "$folder_line" ]; then
  echo -e "$parts\n$folder_line"
else
  echo "$parts"
fi
