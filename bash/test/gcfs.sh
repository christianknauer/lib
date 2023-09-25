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

DebugLoggingConfig 9

__Core_CreateEncryptedTempDir; ec=$?; 
[ ! $ec -eq 0 ] &&  __Core_LibError "$errval" && exit $ec

PlainDir="${retval}"
CipherDir="${retval1}"
Password="${retval2}"
MasterKey="${retval3}"

touch "${PlainDir}"/test1.txt
touch "${PlainDir}"/test2.txt

DebugLs 1 "Cipher dir:" "${CipherDir}" 
DebugLs 1 "Plain dir:" "${PlainDir}" 
DebugMsg 1 "Password: ${Password}"
DebugMsg 1 "Master key: ${MasterKey}"

__Core_CreateEncryptedTempDir; ec=$?; 
[ ! $ec -eq 0 ] &&  __Core_LibError "$errval" && exit $ec

PlainDir="${retval}"
CipherDir="${retval1}"
Password="${retval2}"
MasterKey="${retval3}"

touch "${PlainDir}"/test1.txt
touch "${PlainDir}"/test2.txt

DebugLs 1 "Cipher dir:" "${CipherDir}" 
DebugLs 1 "Plain dir:" "${PlainDir}" 
DebugMsg 1 "Password: ${Password}"
DebugMsg 1 "Master key: ${MasterKey}"

# EOF
