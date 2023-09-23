# file: core.sh

# requirements: basename, readlink

# immutable module options
CORE_NAMESPACE="${CORE_NAMESPACE:=_Core_}"
# mutable module options
CORE_LOGFILE="/dev/null"

# public functions
eval "${CORE_NAMESPACE:1}LibError() { __Core_LibError \"\$@\"; }"
__Core_LibError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[3]}); local line=${BASH_LINENO[2]}; local func=${FUNCNAME[3]}
    # colors
    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

# EOF
