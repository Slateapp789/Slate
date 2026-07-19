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
flutter_bin="$(cd "$repo_dir/../flutter/bin" && pwd)"
ruby_gem_bin="$HOME/.gem/ruby/2.6.0/bin"

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

