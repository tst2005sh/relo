# Augmente le compteur d'erreur (tout en conservant le status courant)
ERROR_INCR() { local r=$?; _ERROR_=$(( ${_ERROR_:-0} + 1)); return $r; };#deps=@errorcodelib

# The function will return 0 (true) only if the current status and $_ERROR_ is 0, else false.
ERROR_CHECK() { [ $? -eq 0 ] && [ ${_ERROR_:-0} -eq 0 ]; };#deps=@errorcodelib

#deps=@errorcodelib=
