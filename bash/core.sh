# file: core.sh

# requirements: basename

# private functions

# for use inside the core module

#eval "__Core_LibDebugI () { __Core_LibDebug \"\$@\"; }"
#eval "__Core_LibErrorI () { __Core_LibError \"\$@\"; }"

# for external use
#eval "__Core_LibDebug () { __Core_LibDebugInternal \"\$@\"; }"
#__Core_LibDebugInternal () {
#    local msg=$1; local source=$(basename ${BASH_SOURCE[3]}); local line=${BASH_LINENO[2]}; local func=${FUNCNAME[3]}
__Core_LibDebug () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[1]}); local line=${BASH_LINENO[0]}; local func=${FUNCNAME[1]}
    # colors
  
    local cColorOff='\033[0m'; local cPurple='\033[0;35m'; local cWhite='\033[0;37m' 
    local logfile="${CORE_LOGFILE:=/dev/null}"

    local Text="[${cPurple}LIBDEBUG${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    [ -z "${CORE_DEBUG}" ] && return 0
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${logfile}" 
}

#eval "__Core_LibError () { __Core_LibErrorInternal \"\$@\"; }"
#__Core_LibErrorInternal () {
#    local msg=$1; local source=$(basename ${BASH_SOURCE[3]}); local line=${BASH_LINENO[2]}; local func=${FUNCNAME[3]}
__Core_LibError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[2]}); local line=${BASH_LINENO[1]}; local func=${FUNCNAME[2]}
    # colors
    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 
    local logfile="${CORE_LOGFILE:=/dev/null}"

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${logfile}" 
}

__Core_CheckBinaries () {
    retval=""
    for app in "$@"
    do
        if ! hash ${app} 2>/dev/null; then
            retval="${retval},${app}"
        else
	    __Core_LibDebug "found $app"
        fi
    done
    retval=${retval:1}
    [ ! -z ${retval} ] && return 1
    return 0
}
 
# checks

[ ! -z "${CORE_ISLOADED}" ] && __Core_LibError "FATAL: core module already loaded (namespace ${CORE_NAMESPACE})" && exit 1

# immutable module options
CORE_NAMESPACE="${CORE_NAMESPACE:=_Core_}"

# mutable module options
#CORE_LOGFILE="/dev/null"
CORE_LOGFILE="lib-bash-core-$$.log"
CORE_DEBUG="${CORE_DEBUG:=}"

# public functions

#eval "${CORE_NAMESPACE:1}LibDebug() { __Core_LibDebugInternal \"\$@\"; }"
#eval "${CORE_NAMESPACE:1}LibError() { __Core_LibErrorInternal \"\$@\"; }"
eval "${CORE_NAMESPACE:1}LibDebug() { __Core_LibDebug \"\$@\"; }"
eval "${CORE_NAMESPACE:1}LibError() { __Core_LibError \"\$@\"; }"

eval "${CORE_NAMESPACE:1}CheckBinaries() { __Core_CheckBinaries \"\$@\"; }"

CORE_ISLOADED="yes"

# EOF
