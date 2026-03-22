default_stdout() { cat "$LOGFILE"; }
default_stderr() { cat >&2 "$ERRFILE"; }
default_return() { exit "$(cat "$RETFILE")"; }
