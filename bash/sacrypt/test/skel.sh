#!/usr/bin/env bash

# file: test.sh

# initialize 

LIB_DIRECTORY="../.."
LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
[ ! -e "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR ($(basename $0)): LIB_DIRECTORY \"${LIB_DIRECTORY}\" not found" >&2 && exit 1

# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# handle command options
USAGE="[-i INFILE -o OUTFILE -k PUBKEYFILE -c CHKFILE -p PASSWORD -I INITFILE -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE  -D CORE_DEBUG]"
Options.ParseOptions "${USAGE}" ${@}

# load logging module 
[ -z "${LOGGING_ISLOADED}" ] && source "${LIB_DIRECTORY}/logging.sh"

__logging_DebugConfig

# log library errors to app log file
CORE_LOGFILE="${LOGGING_LOGFILE}"

# load sacrypt module (use global namespace)
SACRYPT_LIB_DIRECTORY="${LIB_DIRECTORY}/sacrypt"
[ ! -e "${SACRYPT_LIB_DIRECTORY}" ] && echo "$0: ERROR: sacrypt lib directory \"${SACRYPT_LIB_DIRECTORY}\" does not exist" && exit 1
source "${SACRYPT_LIB_DIRECTORY}/sacrypt.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize sacrypt lib" && exit $ec

exit 0

# EOF
