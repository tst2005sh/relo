eval64() {
	if [ "$(echo b2sK | openssl base64 -d 2>/dev/null)" = ok ]; then
		eval "$(openssl base64 -d)";
	elif command -v base64 >/dev/null 2>&1; then
		eval "$(base64 -d)";
	elif command -v openssl >/dev/null 2>&1; then
		eval "$(openssl base64 -d)";
	else
		cat >/dev/null;
		echo >&2 "FATAL: no base64 solution on remote side (PATH=$PATH)";
	fi;
}
