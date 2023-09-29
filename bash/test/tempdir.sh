# file: temp.sh

LIB_DIRECTORY=$(pwd)/..

LOGGING_TIMESTAMP=echo

# checks
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1

# load modules (if not already loaded)

# core
[ -z "${CORE_ISLOADED}" ] && source "${LIB_DIRECTORY}/core.sh"

# logging
[ -z "${LOGGING_NAMESPACE}" ] && LOGGING_NAMESPACE="."; source "${LIB_DIRECTORY}/logging/logging.sh"
[[ ! -z "${LOGGING_ISLOADED}" && "${LOGGING_NAMESPACE}" != "." ]] && echo -e "FATAL ERROR ($(basename $0)): logging module not in global namespace (using \"${LOGGING_NAMESPACE}\")" >&2 && exit 1

# options
source "${LIB_DIRECTORY}/options.sh"

# main
USAGE="[ -I LOGGING_INFO_LEVEL -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE -D CORE_DEBUG]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file
CORE_LOGFILE="${LOGGING_LOGFILE}"

__logging_DebugConfig

# create temporary directory
core_CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  ErrorMsg "$errval" && exit $ec
core_CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  ErrorMsg "$errval" && exit $ec
core_CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  ErrorMsg "$errval" && exit $ec

# EOF
