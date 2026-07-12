#!/bin/zsh
# worksync — синк личной рабочей папки creo-work между компами.
# Одна команда: подтянуть свежее + закоммитить/запушить свои изменения.
# Безопасно для фонового launchd: не виснет (ssh ConnectTimeout), не накладывается (lock),
# тихо выходит при отсутствии сети/изменений. Ошибки — в лог, не на экран.

set -u
REPO="${HOME}/creo-work"
LOG="${REPO}/.worksync.log"
LOCK="${REPO}/.worksync.lock"

cd "$REPO" 2>/dev/null || exit 0

# --- lock: если прошлый запуск ещё идёт (висит сеть) — не стартуем второй ---
if ! mkdir "$LOCK" 2>/dev/null; then
  # lock старше 10 мин считаем протухшим (прошлый запуск умер) и переустанавливаем
  if [ -d "$LOCK" ]; then
    find "$LOCK" -maxdepth 0 -mmin +10 2>/dev/null | grep -q . && rm -rf "$LOCK" && mkdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
trap 'rm -rf "$LOCK"' EXIT INT TERM

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG"; }

# ssh с жёстким таймаутом — главный предохранитель от зависания на плохой сети
export GIT_SSH_COMMAND="ssh -o ConnectTimeout=10 -o BatchMode=yes"
export GIT_TERMINAL_PROMPT=0

# --- обновить INDEX.md (быстрый поиск: что вообще есть в shotlists) ---
build_index() {
  local idx="${REPO}/shotlists/INDEX.md"
  {
    echo "# Shotlists — индекс"
    echo ""
    echo "_Автогенерация worksync. Не редактировать руками._"
    echo ""
    echo "| Файл | Изменён |"
    echo "|---|---|"
    for f in "${REPO}"/shotlists/*.md; do
      [ -e "$f" ] || continue
      case "$f" in */INDEX.md) continue;; esac
      local name="${f:t}"
      local mt
      mt=$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)
      echo "| ${name} | ${mt} |"
    done
  } > "$idx"
}

# --- pull свежего (rebase + autostash, чтобы не спотыкаться о локальные правки) ---
git pull --rebase --autostash --quiet 2>>"$LOG" || { log "pull failed (сеть?) — выхожу тихо"; exit 0; }

build_index

# --- есть ли что коммитить ---
if [ -n "$(git status --porcelain)" ]; then
  git add -A 2>>"$LOG"
  git commit -q -m "worksync: $(hostname -s) $(date '+%Y-%m-%d %H:%M')" 2>>"$LOG"
  if git push --quiet 2>>"$LOG"; then
    log "pushed"
  else
    log "push failed (сеть?) — локально закоммичено, уедет в следующий раз"
  fi
else
  log "nothing to sync"
fi
