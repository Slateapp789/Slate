# Source this file before running Flutter commands from the Workloop repo:
#   source scripts/dev_env.sh

if [ -n "${BASH_SOURCE:-}" ]; then
  script_path="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  script_path="${(%):-%N}"
else
  script_path="$0"
fi

script_dir="$(cd "$(dirname "$script_path")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
ruby_gem_bin="$HOME/.gem/ruby/2.6.0/bin"

if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
  flutter_bin="$FLUTTER_ROOT/bin"
elif [ -x "$repo_dir/../flutter/bin/flutter" ]; then
  flutter_bin="$(cd "$repo_dir/../flutter/bin" && pwd)"
elif command -v flutter >/dev/null 2>&1; then
  flutter_bin="$(cd "$(dirname "$(command -v flutter)")" && pwd)"
elif [ -x "$HOME/Documents/Codex/2026-07-05/are/work/flutter/bin/flutter" ]; then
  # Local pinned fallback used by this repository's existing development setup.
  flutter_bin="$HOME/Documents/Codex/2026-07-05/are/work/flutter/bin"
else
  echo "Workloop: Flutter was not found. Set FLUTTER_ROOT or add flutter to PATH." >&2
  return 1 2>/dev/null || exit 1
fi

case ":$PATH:" in
  *":$flutter_bin:"*) ;;
  *) PATH="$flutter_bin:$PATH" ;;
esac

case ":$PATH:" in
  *":$ruby_gem_bin:"*) ;;
  *) PATH="$ruby_gem_bin:$PATH" ;;
esac

export PATH

case " ${RUBYOPT:-} " in
  *" -rlogger "*) ;;
  *) export RUBYOPT="-rlogger${RUBYOPT:+ $RUBYOPT}" ;;
esac
