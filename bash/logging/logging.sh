# file: logging.sh

# requirements: basename, cat, readlink

# - args and return values are lower case
# - local variables are camel case (upper case first letter)
# - local constants are prefixed with 'c'
# - global variables for return values: retval, retval1, retval2, ... 
# - global variable for error return value: reterr

# module configuration

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=_logging_}"
LOGGING_LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}/logging")

# mutable module options
LOGGING_STYLE="${LOGGING_STYLE:=color}"
LOGGING_INFO_STD_LEVEL="${LOGGING_INFO_STD_LEVEL:=1}"
LOGGING_INFO_LEVEL="${LOGGING_INFO_LEVEL:=0}"
LOGGING_DEBUG_STD_LEVEL="${LOGGING_DEBUG_STD_LEVEL:=1}"
LOGGING_DEBUG_LEVEL="${LOGGING_DEBUG_LEVEL:=0}"
LOGGING_SCRIPTS="${LOGGING_SCRIPTS:=.*}"
LOGGING_FUNCTONS="${LOGGING_FUNCTIONS:=.*}"
LOGGING_TIMESTAMP="${LOGGING_TIMESTAMP:=date +\"%d.%m.%Y %T\"}" # set this to "echo" to disable all timestamps
LOGGING_LOGFILE="${LOGGING_LOGFILE:=/dev/null}"

# initialize library

# checks

# check for lib directory
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR logging module ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1

# core module
# check for core module
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR logging module ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1
# load core module (if not already loaded)
[ -z "${CORE_ISLOADED}" ] && source "${LIB_DIRECTORY}/core.sh"
# import LibError from lib module as __logging_LibError
#eval "__logging_LibError () { core_LibError \"\$@\"; }"

# check for repeated initialization
[ ! -z "${LOGGING_ISLOADED}" ] && core_LibError "FATAL: logging module already loaded (namespace ${LOGGING_NAMESPACE})" && exit 1
# check module directory
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && core_LibError "FATAL: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1

# load additional library files
# colors 
source "${LOGGING_LIB_DIRECTORY}/_colors.sh"

# load other required modules

# global variables

__LOGGING_LAST_LEVEL=5

# global constants

# colors

__logging_ColorOff=$(__Colors_GetColor Color_Off)
__logging_ColorError=$(__Colors_GetColor BRed)
__logging_ColorWarn=$(__Colors_GetColor Yellow)
__logging_ColorInfo=$(__Colors_GetColor Blue)
__logging_ColorDebug=$(__Colors_GetColor Purple)

# private functions

__logging_Stream () {
    local type=$1
    local retval=""

    if [[ "${type}" == "ERROR" || "${type}" == "WARN" ]]; then
	retval=">&2"
    fi
    #if [ "${type}" == "ERROR" ]; then
#	retval=">&2"
#    elif [ "${type}" == "WARN" ]; then
#	retval=">&2"
#    fi

    echo "${retval}"
#    # redirect to stderr
#    [ "${type}" == "ERROR" ] && echo '>&2' && return 0    
#    # no redirection
#    echo ""
}

__logging_FormatFunction () {
    local type=$1
    local func=$2
    local depth=$3
    local retval=" ${func}"

    local cEmptyLine="                                      "
    local cCall="\u2517"
    local cRet=" "
    local cSeq=" "

    local Callsymbol="${cCall}"

    [ ${depth} -eq ${__LOGGING_LAST_LEVEL} ] && Callsymbol="${cSeq}"
    [ ${depth} -lt ${__LOGGING_LAST_LEVEL} ] && Callsymbol="${cRet}"
    [ ${depth} -eq 5 ] && Callsymbol=" "
  
    if [[ "${type}" == "INFO" || "${type}" == "DEBUG" ]]; then
        retval="${cEmptyLine:0:${depth}-5}${Callsymbol}${func}"
    fi
    echo "${retval}"
}

__logging_FormatLevel () {
    local type=$1
    local lvl=$2
    local retval=""
    if [ "${type}" == "INFO" ]; then
#	retval="-${lvl}/${LOGGING_INFO_LEVEL}"
	retval=" (${lvl})"
    elif [ "${type}" == "DEBUG" ]; then
#	retval="-${lvl}/${LOGGING_DEBUG_LEVEL}"
	retval=" (${lvl})"
    else
        echo "${retval}"; return 0
    fi
#    retval=$(printf ' %7s' "${retval}")
    echo "${retval}"
}

__logging_TextColor () {
    local type=$1
    local color=$__logging_ColorOff
    if [ "${type}" == "INFO" ]; then
	color=$__logging_ColorInfo
    elif [ "${type}" == "DEBUG" ]; then
	color=$__logging_ColorDebug
    elif [ "${type}" == "WARN" ]; then
	color=$__logging_ColorWarn
    elif [ "${type}" == "ERROR" ]; then
	color=$__logging_ColorError
    fi
    echo "$color"
}

__logging_FormatMsg () {
    local type=$1
    local lvl=$2
    local msg=$3

    local cWhite=$(__Colors_GetColor BWhite)
    local cEmptyLine="                                      "

    local Color="$(__logging_TextColor ${type})"
    local Level="$(__logging_FormatLevel ${type} ${lvl})"
    local Time=$(eval $LOGGING_TIMESTAMP)
    local Type=$(printf '%-5s' "${type}")
    local Depth=${#FUNCNAME[@]}
    local Func=${FUNCNAME[4]}
    #local Func="${cEmptyLine:0:${#FUNCNAME[@]}-5}${FUNCNAME[4]}"
    Func="$(__logging_FormatFunction ${type} ${Func} ${Depth})"
    local Source=$(basename ${BASH_SOURCE[4]})
    local LineNo=${BASH_LINENO[3]}

    [ "${Time}" != "" ] && Time=" ${Time}"

    __LOGGING_LAST_LEVEL=$Depth

    retval="[${Color}${Type}${__logging_ColorOff}${Level}${Time}${cWhite}${Func} (${Source}:${LineNo})${__logging_ColorOff}] ${msg}" 
}

__logging_IsInactive () {
    local Script=$(basename ${BASH_SOURCE[3]})
    local Function=${FUNCNAME[3]}

    [[ "${Script}" =~ ${LOGGING_SCRIPTS} && \
	    "${Function}" =~ ${LOGGING_FUNCTIONS} ]] && return 1
    return 0
}

__logging_InsufficientLevel () {
    local lvl=$1
    local threshold=$2
    (( ${lvl} <= ${threshold} )) && return 1
    return 0
}

__logging_Msg () {
    local type=$1; local lvl=$2; local msg=$3

    #local Text=$(__logging_FormatMsg "${type}" ${lvl} "${msg}")
    __logging_FormatMsg "${type}" ${lvl} "${msg}"; local Text=${retval}
    local Stream=$(__logging_Stream "${type}")
    #local Depth=${#FUNCNAME[@]}; ((Depth++))
    #__LOGGING_LAST_LEVEL=$Depth

    echo -e "${Text}" >> "${LOGGING_LOGFILE}"
    eval "echo -e \"\$Text\" $Stream"
}

__logging_MsgCat () {
    local type=$1; local lvl=$2; local msg=$3
    local file=$4; local source=$5; [ "${source}" == "" ] && source="${file}"

    local Stream=$(__logging_Stream "${type}")
    #local Text=$(__logging_FormatMsg "${type}" ${lvl} "(content of \"${source}\") ${msg}")
    __logging_FormatMsg "${type}" ${lvl} "(content of \"${source}\") ${msg}"; local Text=${retval}

    # write to log file & stream
    echo -e -n "${Text}\n"            >> "${LOGGING_LOGFILE}" 
    eval "echo -e -n \"\$Text\\n\"        $Stream"          

    # check if file exists
    [ ! -f "${file}" ] && core_LibError "file \"${file}\" does not exist" && return 0

    # write to log file
    echo -e -n "$__logging_ColorInfo" >> "${LOGGING_LOGFILE}" 
    cat "${file}"                     >> "${LOGGING_LOGFILE}" 
    echo -e -n "$__logging_ColorOff"  >> "${LOGGING_LOGFILE}" 

    # write to output stream (stdout/stderr)
    eval "echo -e -n \"$__logging_ColorInfo\" $Stream"     
    eval "cat \"${file}\"                     $Stream"                         
    eval "echo -e -n \"$__logging_ColorOff\"  $Stream" 
}

# public functions

eval "${LOGGING_NAMESPACE:1}DebuggingIsActive() { __logging_DebuggingIsActive \"\$@\"; }"
__logging_DebuggingIsActive () {
    local lvl=$1

    __logging_IsInactive && return 1
    __logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 1
    return 0
}

eval "${LOGGING_NAMESPACE:1}DebugMsg() { __logging_DebugMsg \"\$@\"; }"
__logging_DebugMsg () {
    local lvl=$1; local msg=$2

    __logging_IsInactive && return 0
    __logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __logging_Msg DEBUG ${lvl} "${msg}"
}

eval "${LOGGING_NAMESPACE:1}DebugCat() { __logging_DebugCat \"\$@\"; }"
__logging_DebugCat () {
    local lvl=$1; local msg=$2; local file=$3; local source=$4

    __logging_IsInactive && return 0
    __logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __logging_MsgCat DEBUG ${lvl} "${msg}" "${file}" "${source}"

}

eval "${LOGGING_NAMESPACE:1}DebugLs() { __logging_DebugLs \"\$@\"; }"
__logging_DebugLs () {
    local lvl=$1; local msg=$2; local dir=$3

    __logging_IsInactive && return 0
    __logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    [ ! -d "${dir}" ] && \
        __logging_Msg DEBUG ${lvl} "${msg}" && \
	core_LibError "directory \"${dir}\" does not exist" && return 0

    local tmp_file=$(mktemp)
    [ ! -f "${tmp_file}" ] && \
	core_LibError "cannot create temp file \"${tmp_file}\"" && return 0

    ls -laR "${dir}" > "${tmp_file}"
    __logging_MsgCat DEBUG ${lvl} "${msg}" "${tmp_file}" "${dir}"
    rm -f -- "${tmp_file}"
}

__logging_DebugConfig () {
    core_LibDebug "LOGGING_NAMESPACE       = $LOGGING_NAMESPACE"
    core_LibDebug "LOGGING_LIB_DIRECTORY   = ${LOGGING_LIB_DIRECTORY}"
    core_LibDebug "LOGGING_STYLE           = $LOGGING_STYLE"
    core_LibDebug "LOGGING_INFO_STD_LEVEL  = $LOGGING_INFO_STD_LEVEL"
    core_LibDebug "LOGGING_DEBUG_STD_LEVEL = $LOGGING_DEBUG_STD_LEVEL"
    core_LibDebug "LOGGING_INFO_LEVEL      = $LOGGING_INFO_LEVEL"
    core_LibDebug "LOGGING_DEBUG_LEVEL     = $LOGGING_DEBUG_LEVEL"
    core_LibDebug "LOGGING_SCRIPTS         = $LOGGING_SCRIPTS"
    core_LibDebug "LOGGING_FUNCTIONS       = $LOGGING_FUNCTIONS"
    core_LibDebug "LOGGING_TIMESTAMP       = $LOGGING_TIMESTAMP"
    core_LibDebug "LOGGING_LOGFILE         = $LOGGING_LOGFILE"
}

# info

eval "${LOGGING_NAMESPACE:1}InfoMsg() { __logging_InfoMsg \"\$@\"; }"
__logging_InfoMsg () {
    local nargs=$#; local lvl=${LOGGING_INFO_STD_LEVEL}; local msg=$1
    ((${nargs} == 2)) && lvl=$1 && msg=$2

    __logging_IsInactive && return 0
    __logging_InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __logging_Msg INFO ${lvl} "${msg}"
}

eval "${LOGGING_NAMESPACE:1}InfoCat() { __logging_InfoCat \"\$@\"; }"
__logging_InfoCat () {
    local nargs=$#; local lvl=${LOGGING_INFO_STD_LEVEL}; local msg=$1; local file=$2
    ((${nargs} == 3)) && lvl=$1 && msg=$2; local file=$2

    __logging_IsInactive && return 0
    __logging_InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __logging_MsgCat INFO ${lvl} "${msg}" "${file}"
}

# warn

eval "${LOGGING_NAMESPACE:1}WarnMsg() { __logging_WarnMsg \"\$@\"; }"
__logging_WarnMsg () {
    local msg=$1

    __logging_Msg WARN 0 "${msg}"
}

# error

eval "${LOGGING_NAMESPACE:1}ErrorMsg() { __logging_ErrorMsg \"\$@\"; }"
__logging_ErrorMsg () {
    local msg=$1

    __logging_Msg ERROR 0 "${msg}"
}

eval "${LOGGING_NAMESPACE:1}ErrorCat() { __logging_ErrorCat \"\$@\"; }"
__logging_ErrorCat () {
    local msg=$1; local file=$2

    __logging_MsgCat ERROR 0 "${msg}" "${file}"
}

LOGGING_ISLOADED="yes"

# EOF
