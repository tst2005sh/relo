
split_user_host() {
	case "$user_host" in
	(*@*@*)
		echo >&2 "ERROR: Syntax error in user_host=$user_host"; exit 1
	;;
	(*@?*)
		user="${user_host%@*}"
		host="${user_host#*@}"
	;;
	(*)
		user=''
		host="$user_host"
	;;
	esac
	[ -n "$user" ] || user=root
}
