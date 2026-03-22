
# <codegen>
codegen_eval64() {
	local f="$1";shift

	cat "$BASEDIR/lib/codegen/eval64.code.sh"

	local value="$(date|md5sum|cut -d\  -f1)"
	printf '%q ' eval64 "$@"
	printf '<<%s\n' "$value"

	if [ -f "$f" ]; then
		base64 "$f"
	elif [ -f "$f.codegen.sh" ]; then
		if [ -x "$f.codegen.sh" ]; then
			{ "$f.codegen.sh" || exit 1; } | base64
		else
			echo >&2 "ERROR: missing execution permission on $f.codegen.sh"
			exit 1
		fi
	else
		echo >&2 'ERROR: no such file ('"$f"'|'"$f"'.codegen.sh)'
		exit 1
	fi

	echo "$value"
}
# </codegen>
