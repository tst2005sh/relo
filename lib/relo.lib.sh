relo_help() {
	echo 'Usage: '"$0"' -d <actiondir> <target>'
	echo 'Usage: '"$0"' -d <actiondir1> [-d <actiondir2>] [--] <target>'
	echo 'Usage: '"$0"' -d <actiondir1> [-d <actiondir2>] [--args ...any args...] <target>'
	echo 'Options:'
	echo '  --debug-keeplog'
	echo '  --re|--foreground|--do-for'
	echo '  --allow-invalid-dirname'
	echo '  --eval8|--eval64'
	echo 'Env:'
	echo '  RELO_SSH_TIMEOUT=5'
}

relo_actiondir_validname() {
	case "$(basename "$1")" in
	(*.relo|*.re) return 0;;
	esac
	return 1
}

relo_actiondir_is_valid() {
	if [ ! -d "$1" ]; then
		echo >&2 "No such directory $1"
		false
	else
		[ "${allow_invalid_dirname}" = true ] ||
		relo_actiondir_validname "$1"
	fi
	return $?
}

relo_actiondirs_are_valid() {
	local actiondirs="$1";shift
	for actiondir in $actiondirs; do
		if ! relo_actiondir_is_valid "$actiondir"; then
			echo >&2 "Invalid actiondir $actiondir"
			return 1
		fi
	done
}

relo_do_remote_1actionfile_for_1target_in_dir() {
	local _ERROR_
	local actionfile="$1";shift
	local target="$1";shift
	local dir="$1";shift

	local user_host="$target"
	split_user_host
	#echo >&2 "#DEBUG: user=$user host=$host"

	#local adir="$(dirname "$actionfile")"
	#if [ -r "$adir/options.sh" ]; then
	#	#echo >&2 "#DEBUG: load $adir/options.sh"
	#	. "$actiondir/options.sh"
	#fi

	local action="$(basename "$actiondir")"

	local auto_foreground
	case "$action" in
	(*.re) auto_foreground=true;;
	(*.relo) auto_foreground=false;;
	esac

	relo_do_internalcode() {
	(
		#touch "$dir/$action.run"
		remotecode="$(codegen "$actionfile" "$@")"
		(
			set --
			if [ -n "$RELO_SSH_UserKnownHostsFile" ]; then
				set -- -o "UserKnownHostsFile=${RELO_SSH_UserKnownHostsFile}"
			fi
			set -- "$@" -o StrictHostKeyChecking=accept-new
			set -- "$@" -o PasswordAuthentication=no
			ssh "$@" -o "ConnectTimeout=${RELO_SSH_TIMEOUT:-5}" -n -l "$user" "$host" "$remotecode"
			r=$?
			echo "$r" > "$dir/$action.ret"
			exit $r
		)
		r=$?
		#rm -f -- "$dir/$action.run"
		exit $r
	)
	}

	if [ "$foreground" = "true" ] || [ "$foreground" = auto ] && [ "$auto_foreground" = true ]; then
		#touch "$dir/${action}.log" "$dir/${action}.err"
		relo_do_internalcode "$@" || ERROR_INCR
	else
		relo_do_internalcode "$@" >"$dir/${action}.log" 2>"$dir/${action}.err" || ERROR_INCR
	fi

	if [ -f "$dir/$action.ret" ] && [ "$(cat "$dir/$action.ret")" != "0" ]; then
		ERROR_INCR
	fi
	ERROR_CHECK
	return $?
}

relo_do_local_1actionfile_for_1target_in_dir() {
	local actionfile="$1";shift
	local target="$1";shift
	local dir="$1";shift

	case "$actionfile" in
	(/*) ;;
	(*) actionfile="$STARTPWD/$actionfile" ;;
	esac

	(
		export TARGET="$target"
		export LOGFILE="$action.log"
		export ERRFILE="$action.err"
		export RETFILE="$action.ret"
		export ACTIONDIR="$(dirname "$actionfile")"
		cd "$dir" && (
			. "$BASEDIR/lib/default_helpers.lib.sh"
			. "$BASEDIR/lib/default_helpers-v2.lib.sh"
			. "$BASEDIR/lib/default_helpers-v3.lib.sh"
			#set -- "$@"
			. "$actionfile"
			default_stderr
			default_return
		)
	)
}

# args: $actiondirs $target $resultdir
relo_do_actions_for_1target_in_resultdir() {
	local _ERROR_
	local actiondirs="$1";shift
	local target="$1";shift
	local resultdir="$1";shift
	local dir="$resultdir/$target"
	mkdir -- "$dir"
	echo '{"target":"'"$target"'"}' > "$dir/target.json"

	for actiondir in $actiondirs; do
		action="$(basename "$actiondir")"

		# ${action}/remote
		#local actionfile="$BASEDIR/actions/$action/remote.sh"
		local actionfile="$actiondir/remote.sh"
		if [ ! -f "$actionfile" ] && [ ! -f "$actionfile.codegen.sh" ]; then
			echo >&2 "ERROR: no such REMOTE actionfile $actionfile or $actionfile.codegen.sh"
			exit 1
		fi
		relo_do_remote_1actionfile_for_1target_in_dir "$actionfile" "$target" "$dir" "$@" || ERROR_INCR

		# ${action}/local
		[ "$foreground" = "true" ] ||
		case "$action" in
		(*.re) true ;;
		(*) false ;;
		esac ||
		{
			local actionfile="$actiondir/local.sh"
			if [ -f "$actionfile" ]; then
				relo_do_local_1actionfile_for_1target_in_dir "$actionfile" "$target" "$dir" "$@" || ERROR_INCR
			else
				echo >&2 "#INFO: no such LOCAL actionfile $actionfile"
			fi
		}
	done
	ERROR_CHECK
	return $?
}


relo() {
	local _ERROR_
	local actiondirs=''
	local opt_keeplop=false
	local allow_args=false 
	local foreground='auto'
	local allow_invalid_dirname=false
	codegen() { codegen_eval8 "$@";}
	if [ $# -eq 0 ]; then
		set -- --help
	fi
	while [ $# -gt 0 ]; do
		case "$1" in
		(--help)
			relo_help
			exit 0
		;;
		(--debug-keeplog) opt_keeplog=true ;;
		(--re|--foreground|--do-for) foreground=true ;;
		(--allow-invalid-dirname) allow_invalid_dirname=true ;;
		(--eval8) codegen() { codegen_eval8 "$@";} ;;
		(--eval64) codegen() { codegen_eval64 "$@";} ;;
		(-d)	shift
			if ! relo_actiondir_is_valid "$1"; then
				echo >&2 "$0"': invalid actiondir '"$1"' (must ends by .relo or .re). If you know what you are doing you can bypass the check by using --allow-invalid-dirname'
				exit 1
			fi
			actiondirs="${actiondirs} $1"
		;;
		(--args)
			if [ -z "$actiondirs" ]; then
				echo >&2 "Syntax error: use all -d <action> before --args ..."
				exit 1
			fi
			allow_args=true
			break
		;;
		(--)
			shift;break
		;;
		(--*)
			echo >&2 '$0:ERROR: invalid option '"$1"''; exit 11
		;;
		(-*)
			echo >&2 '$0:ERROR: invalid option '"$1"''; exit 12
		;;
		(*)
			break
		;;
		esac
		shift
	done

	local target=''
	case "$1" in
	('--args')
		# renove the --args argument
		shift;
		# get the last arg as target
		target="${@:$#:1}"
		# remove the last arg but keep all other args
		set -- "${@:1:$#-1}" # remove the last arg #require(bash)#
	;;
	(*)
		if [ $# -gt 1 ]; then
			echo >&2 "ERROR invalid syntax. The last argument must be the target. If you want pass arbitrary arguments, see the --args option."
			exit 1
		fi
		if [ $# -ne 1 ]; then
			echo >&2 "ERROR missing target"
			exit 1
		fi
		target="$1";shift
	;;
	esac

	local resultdir=$(mktemp -d "/tmp/$(basename "$0" .sh).$(date +%Y%m%d.%H%M).${target}.XXXXXXXX")
	if ${opt_keeplog:-false}; then
		echo >&2 "DEBUG(keeplog): resultdir=$resultdir"
	else
		trap "rm -rf -- '$resultdir'" EXIT
	fi

	#echo >&2 "#DEBUG: target=$target resultdir=$resultdir"
	#echo >&2 "#DEBUG: args(len=$#): $*"

	if [ -n "$actiondirs" ]; then
		relo_actiondirs_are_valid || return 1

		relo_do_actions_for_1target_in_resultdir "$actiondirs" "$target" "$resultdir" "$@" || ERROR_INCR
	else
		echo >&2 "$0: nothing todo"
	fi
	ERROR_CHECK
	return $?
}
