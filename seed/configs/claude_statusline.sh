#!/usr/bin/env bash
input=$(cat)

# ---------------------------------------------------------------------------
# Helper: pad a plain string to a given width (no ANSI codes in the string).
# Usage: pad "string" width
# ---------------------------------------------------------------------------
pad() {
  local str="$1"
  local width="$2"
  printf "%-${width}s" "$str"
}

# ---------------------------------------------------------------------------
# Helper: column width = max(len(header), len(value))
# ---------------------------------------------------------------------------
col_width() {
  local h="${#1}"
  local v="${#2}"
  echo $(( h > v ? h : v ))
}

# ---------------------------------------------------------------------------
# Extract values from JSON input
# ---------------------------------------------------------------------------
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_read=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
window_size=$(echo "$input"  | jq -r '.context_window.context_window_size // 0')

tokens_used=$(( input_tokens + cache_read + output_tokens ))
ctx_val="${tokens_used}/${window_size}"

# ---------------------------------------------------------------------------
# Session plan usage via cached API call to /api/oauth/usage
# Cache for 5 minutes to avoid per-render API calls
# ---------------------------------------------------------------------------
USAGE_CACHE="/tmp/.claude_usage_cache"
CACHE_TTL=300  # seconds

session_val="n/a"
_creds="$HOME/.claude/.credentials.json"
if [ -f "$_creds" ] && command -v jq >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  # Refresh cache if stale or missing
  _now=$(date +%s)
  _cache_ts=0
  [ -f "${USAGE_CACHE}.ts" ] && _cache_ts=$(cat "${USAGE_CACHE}.ts" 2>/dev/null)
  if [ $(( _now - _cache_ts )) -gt $CACHE_TTL ] || [ ! -f "$USAGE_CACHE" ]; then
    _token=$(jq -r '.claudeAiOauth.accessToken // empty' "$_creds" 2>/dev/null)
    if [ -n "$_token" ]; then
      _resp=$(curl -s --max-time 4 \
        "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $_token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" \
        -H "User-Agent: claude-code/statusline" 2>/dev/null)
      if echo "$_resp" | jq -e '.five_hour' >/dev/null 2>&1; then
        echo "$_resp" > "$USAGE_CACHE"
        echo "$_now" > "${USAGE_CACHE}.ts"
      fi
    fi
  fi
  # Read from cache
  if [ -f "$USAGE_CACHE" ]; then
    _util=$(jq -r '.five_hour.utilization // empty' "$USAGE_CACHE" 2>/dev/null)
    _resets=$(jq -r '.five_hour.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)
    if [ -n "$_util" ]; then
      _used_int=$(printf '%.0f' "$_util")
      _left=$(( 100 - _used_int ))
      if [ -n "$_resets" ]; then
        _reset_time=$(date -d "$_resets" "+%H:%M" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${_resets%%.*}" "+%H:%M" 2>/dev/null || echo "")
        [ -n "$_reset_time" ] && session_val="${_left}% @${_reset_time}" || session_val="${_left}% left"
      else
        session_val="${_left}% left"
      fi
    fi
  fi
fi

tid="${TID:-}"
[ ${#tid} -gt 8 ] && tid="${tid:0:4}..${tid: -4}"
provider="${PROVIDER:-}"

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
cwd="${cwd:-$(pwd)}"

in_git=false
git_status=""
project_val=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  in_git=true
  project_val=$(cd "$cwd" && docslug 2>/dev/null)

  # Run gsw as a background watcher keyed on workspace path, read latest output from temp file
  if command -v gsw >/dev/null 2>&1; then
    _gsw_key=$(printf '%s' "$cwd" | md5sum | cut -c1-8)
    _gsw_out="/tmp/gsw_status_${_gsw_key}"
    _gsw_pid="/tmp/gsw_pid_${_gsw_key}"
    _running=false
    if [ -f "$_gsw_pid" ]; then
      _pid=$(cat "$_gsw_pid" 2>/dev/null)
      kill -0 "$_pid" 2>/dev/null && _running=true
    fi
    if ! $_running; then
      ( cd "$cwd" && gsw --format '{branch} +{staged} ~{modified} ?{untracked} ⇡{ahead}⇣{behind}' 2>/dev/null \
          | while IFS= read -r line; do echo "$line" > "$_gsw_out"; done ) &
      echo $! > "$_gsw_pid"
      disown $! 2>/dev/null || true
    fi
    [ -f "$_gsw_out" ] && git_status=$(cat "$_gsw_out" 2>/dev/null)
  fi
fi

# ---------------------------------------------------------------------------
# Build ordered list of active columns: (header, value, color_code) tuples
# stored in parallel arrays.
# ---------------------------------------------------------------------------
headers=()
values=()
colors=()   # ANSI 256-color index for the value row

if [ -n "$tid" ]; then
  headers+=("TID");     values+=("$tid");      colors+=("214")
fi
if [ -n "$provider" ]; then
  headers+=("PROVIDER"); values+=("$provider"); colors+=("81")
fi

headers+=("CTX");     values+=("$ctx_val");     colors+=("190")
headers+=("SESSION"); values+=("$session_val"); colors+=("148")

if $in_git; then
  [ -n "$project_val" ] && { headers+=("PROJECT"); values+=("$project_val"); colors+=("213"); }
  [ -n "$git_status" ]  && { headers+=("GIT");     values+=("$git_status");  colors+=("83");  }
fi

# ---------------------------------------------------------------------------
# Compute per-column widths
# ---------------------------------------------------------------------------
widths=()
for i in "${!headers[@]}"; do
  widths+=("$(col_width "${headers[$i]}" "${values[$i]}")")
done

# ---------------------------------------------------------------------------
# Render header row (plain, dimmed)
# ---------------------------------------------------------------------------
sep_plain=" | "
header_line=""
value_line=""

for i in "${!headers[@]}"; do
  w="${widths[$i]}"
  col_header="$(pad "${headers[$i]}" "$w")"
  col_value="$(pad "${values[$i]}"   "$w")"

  if [ $i -eq 0 ]; then
    header_line="${header_line}$(printf '\e[38;5;240m%s\e[0m' "$col_header")"
    value_line="${value_line}$(printf '\e[38;5;%sm%s\e[0m' "${colors[$i]}" "$col_value")"
  else
    header_line="${header_line}$(printf '\e[38;5;240m%s%s\e[0m' "$sep_plain" "$col_header")"
    value_line="${value_line}$(printf '\e[38;5;240m%s\e[38;5;%sm%s\e[0m' "$sep_plain" "${colors[$i]}" "$col_value")"
  fi
done

printf "%s\n%s\n" "$header_line" "$value_line"
