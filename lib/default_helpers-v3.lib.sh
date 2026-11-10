default_stdout_v3() {
	jq -cMR '{"target":(env.TARGET),"std":"out","line":.}' "$LOGFILE"
}

default_stderr_v3() {
	jq -cMR --arg RET "$(cat "$RETFILE")" '
		[.,inputs]|map( {"return":($RET|tonumber),"line":gsub("\\r$";"")|gsub("^ssh: connect to host [^ ]+ port ";"ssh: connect to port ")|(fromjson? // .)})[] | ({"target":(env.TARGET),"stderr":true}+.)
	' "$ERRFILE"
}
default_stderr() {
	default_stderr_v3 "$@" >&2; 
}

default_return_v3() {
	exit "$(cat "$RETFILE")";
}
default_return() {
	default_return_v3 "$@";
}
