# file: temp.sh

LIB_DIRECTORY=$(pwd)/..

LOGGING_TIMESTAMP=echo

# checks
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1

# load modules (if not already loaded)
# core
[ -z "${CORE_NAMESPACE}" ] && source "${LIB_DIRECTORY}/core.sh"
# logging
[ -z "${LOGGING_NAMESPACE}" ] && LOGGING_NAMESPACE="."; source "${LIB_DIRECTORY}/logging/logging.sh"
# load temp module (use global namespace)
TEMP_NAMESPACE="."; source "${LIB_DIRECTORY}/temp.sh"
# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# main
USAGE="[ -I LOGGING_INFO_LEVEL -D LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE ]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file
CORE_LOGFILE="${LOGGING_LOGFILE}"

DebugLoggingConfig 9

# create temporary directory
CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  Logging_ErrorMsg "$retval" && exit $ec
CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  Logging_ErrorMsg "$retval" && exit $ec
CreateTempDir; ec=$?; TEMPD=$retval
[ ! $ec -eq 0 ] &&  Logging_ErrorMsg "$retval" && exit $ec

# EOF
