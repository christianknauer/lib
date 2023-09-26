#!/usr/bin/env bash

# file: test.sh

# initialize 

LIB_DIRECTORY="../.."
LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
[ ! -e "${LIB_DIRECTORY}" ] && echo "$0 (sa-crypt lib) ERROR: lib directory \"${LIB_DIRECTORY}\" does not exist" && exit 1

# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# handle command options
USAGE="[-i INFILE -o OUTFILE -k PUBKEYFILE -c CHKFILE -p PASSWORD -I INITFILE -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE  -D CORE_DEBUG]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file

# load logging module (use global namespace)
LOGGING_LIB_DIRECTORY="${LIB_DIRECTORY}/logging"
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && echo "$0: ERROR: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1
LOGGING_NAMESPACE="." source "${LOGGING_LIB_DIRECTORY}/logging.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize logging lib" && exit $ec
DebugLoggingConfig 9

CORE_LOGFILE="${LOGGING_LOGFILE}"

# load sacrypt module (use global namespace)
SACRYPT_LIB_DIRECTORY="${LIB_DIRECTORY}/sacrypt"
[ ! -e "${SACRYPT_LIB_DIRECTORY}" ] && echo "$0: ERROR: sacrypt lib directory \"${SACRYPT_LIB_DIRECTORY}\" does not exist" && exit 1
source "${SACRYPT_LIB_DIRECTORY}/sacrypt.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize sacrypt lib" && exit $ec

exit 0

# EOF
