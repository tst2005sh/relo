default_stdout_v2() {
	grep -H '' "$LOGFILE" | sed -e 's,^,'"$TARGET"'/,g';
}

default_stderr_v2() {
	{ grep -H '' "$ERRFILE" | sed -e 's,^,'"$TARGET"'/,g'; } >&2;
}
default_stderr() {
	default_stderr_v2 "$@";
}

default_return_v2() {
	local v;v="$(cat "$RETFILE")"
	[ "$v" = "0" ] || echo >&2 "$TARGET/$ERRFILE: error code returned: $(cat "$RETFILE")";
	exit "$(cat "$RETFILE")";
}
default_return() {
	default_return_v2 "$@";
}
