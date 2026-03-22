
base8_encode() {
	od -t o1 -An | tr \  \\\\ | tr -d \\n;
	echo;
}

# <codegen>
codegen_eval8() {
	local f="$1";shift

	cat "$BASEDIR/lib/codegen/eval8.code.sh"

	local value="$(date|md5sum|cut -d\  -f1)"
	value="Z"
	printf '%q ' eval8 "$@"
	printf '<<%s\n' "$value"

	if [ -f "$f" ]; then
		base8_encode <"$f"
	elif [ -f "$f.codegen.sh" ]; then
		if [ -x "$f.codegen.sh" ]; then
			{
				"$f.codegen.sh" ||
				{ echo >&2 "ERROR: internal error ($?) in $fcodegen.sh"; exit 1; }
			} | base8_encode
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
