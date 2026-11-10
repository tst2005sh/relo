#!/bin/bash

STARTPWD="$(pwd)"
cd -- "$(dirname "$(readlink -f "$0")")/.." || exit 1
BASEDIR="$(pwd)"
cd -- "$STARTPWD" || exit 1

. "$BASEDIR/lib/errorcode.lib.sh" || exit 11
. "$BASEDIR/lib/codegen-eval64.lib.sh" || exit 21
. "$BASEDIR/lib/codegen-eval8.lib.sh" || exit 22
. "$BASEDIR/lib/split_user_host.lib.sh" || exit 31

. "$BASEDIR/lib/relo.lib.sh" || exit 101

relo "$@"
exit $?
