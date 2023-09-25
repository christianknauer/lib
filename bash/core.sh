# file: core.sh

# requirements: basename

# checks

[ ! -z "${CORE_ISLOADED}" ] && __Core_LibError "FATAL: core module already loaded" && exit 1

# module options

CORE_LOGFILE="${CORE_LOGFILE:=lib-bash-core-$(basename $0)-$$.log}"
CORE_DEBUG="${CORE_DEBUG:=}"

# global variables

__CORE_LIST_OF_TEMP_DIRS=""

# private functions

__Core_CleanupTempOnExitP () {
    __Core_LibDebug "removing temporary directories ${__CORE_LIST_OF_TEMP_DIRS}"
    eval "rm -rf ${__CORE_LIST_OF_TEMP_DIRS}"
}

# functions

__Core_LibDebug () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[1]}); local line=${BASH_LINENO[0]}; local func=${FUNCNAME[1]}

    local cColorOff='\033[0m'; local cPurple='\033[0;35m'; local cWhite='\033[0;37m' 

    local Text="[${cPurple}LIBDEBUG${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    [ -z "${CORE_DEBUG}" ] && return 0
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

__Core_LibError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[2]}); local line=${BASH_LINENO[1]}; local func=${FUNCNAME[2]}

    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"

    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

# check for a list of binaries
#
# returns 0 if all arguments are found in PATH
# returns 1 else
#           [errval] contains a comma separated string of 
#           arguments that are not found in PATH

__Core_CheckBinaries () {
    errval=""

    for app in "$@"
    do
        if ! hash ${app} 2>/dev/null; then
            errval="${errval},${app}"
        fi
    done
    errval=${errval:1}
    [ ! -z ${errval} ] && return 1
    return 0
}

# create directory in /tmp that will be removed on script exit
#
# returns 0 if the directory was created successfully in /tmp
#           [retval] contains the name of the directory
# returns 1 if the directory could not be created in /tmp
#           [errval] contains the error message

__Core_CreateTempDir () {
    retval=""; errval=""

    # create temporary directory and store its name in a variable.
    tempd=$(mktemp -d)

    # check if the temp directory was created successfully.
    [ ! -e "${tempd}" ] && errval="failed to create temporary directory" && return 1

    __CORE_LIST_OF_TEMP_DIRS="${__CORE_LIST_OF_TEMP_DIRS} \"${tempd}\""

    # make sure the temp directory is in /tmp.
    [[ ! "${tempd}" = /tmp/* ]] && errval="temporary directory not in /tmp" && return 1

    __Core_LibDebug "created temporary directory \"${tempd}\""

    retval="${tempd}"
    return 0
}

# module init code

# make sure the temp directories get removed on script exit
trap "exit 1" HUP INT PIPE QUIT TERM
trap "__Core_CleanupTempOnExitP" EXIT
 
CORE_ISLOADED="yes"

# EOF
