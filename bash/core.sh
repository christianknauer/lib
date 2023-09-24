# file: core.sh

# requirements: basename

# immutable module options
CORE_NAMESPACE="${CORE_NAMESPACE:=_Core_}"
# mutable module options
CORE_LOGFILE="/dev/null"

# private functions

eval "__Core_LibError () { __Core_LibErrorInternal \"\$@\"; }"
__Core_LibErrorInternal () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[3]}); local line=${BASH_LINENO[2]}; local func=${FUNCNAME[3]}
    # colors
    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

__Core_CheckBinaries () {
    retval=""
    for app in "$@"
    do
        if ! hash ${app} 2>/dev/null; then
            retval="${retval},${app}"
        fi
    done
    retval=${retval:1}
    [ ! -z $retval ] && return 1
    return 0
}
 
# checks

[ ! -z "${CORE_ISLOADED}" ] && __Core_LibError "FATAL: core module already loaded (namespace ${CORE_NAMESPACE})" && exit 1
CORE_ISLOADED="${CORE_ISLOADED:=yes}"

# public functions

eval "${CORE_NAMESPACE:1}LibError() { __Core_LibErrorInternal \"\$@\"; }"
eval "${CORE_NAMESPACE:1}CheckBinaries() { __Core_CheckBinaries \"\$@\"; }"

# EOF
