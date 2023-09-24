# file: logging.sh

# requirements: basename, cat, readlink

# - args and return values are lower case
# - local variables are camel case (upper case first letter)
# - local constants are prefixed with 'c'
# - global variables for return values: retval, retval1, retval2, ... 
# - global variable for error return value: reterr

# module configuration

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=_Logging_}"
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
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR logging module ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR logging module ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1
# load core (if not already loaded)
[ -z "${CORE_NAMESPACE}" ] && source "${LIB_DIRECTORY}/core.sh"

# imports
# import LibError from lib as __Logging_LibError
eval "__Logging_LibError () { ${CORE_NAMESPACE:1}LibError \"\$@\"; }"

# checks
[ ! -z "${LOGGING_ISLOADED}" ] && __Logging_LibError "FATAL: logging module already loaded (namespace ${LOGGING_NAMESPACE})" && exit 1
# module directory
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && __Logging_LibError "FATAL: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1

# load additional library files

# colors 
source "${LOGGING_LIB_DIRECTORY}/_colors.sh"

# load required modules

# global variables

__LOGGING_LAST_LEVEL=5

# global constants

# colors

__Logging_ColorOff=$(__Colors_GetColor Color_Off)
__Logging_ColorError=$(__Colors_GetColor BRed)
__Logging_ColorWarn=$(__Colors_GetColor Yellow)
__Logging_ColorInfo=$(__Colors_GetColor Blue)
__Logging_ColorDebug=$(__Colors_GetColor Purple)

# private functions

__Logging_Stream () {
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

__Logging_FormatFunction () {
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

__Logging_FormatLevel () {
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

__Logging_TextColor () {
    local type=$1
    local color=$__Logging_ColorOff
    if [ "${type}" == "INFO" ]; then
	color=$__Logging_ColorInfo
    elif [ "${type}" == "DEBUG" ]; then
	color=$__Logging_ColorDebug
    elif [ "${type}" == "WARN" ]; then
	color=$__Logging_ColorWarn
    elif [ "${type}" == "ERROR" ]; then
	color=$__Logging_ColorError
    fi
    echo "$color"
}

__Logging_FormatMsg () {
    local type=$1
    local lvl=$2
    local msg=$3

    local cWhite=$(__Colors_GetColor BWhite)
    local cEmptyLine="                                      "

    local Color="$(__Logging_TextColor ${type})"
    local Level="$(__Logging_FormatLevel ${type} ${lvl})"
    local Time=$(eval $LOGGING_TIMESTAMP)
    local Type=$(printf '%-5s' "${type}")
    local Depth=${#FUNCNAME[@]}
    local Func=${FUNCNAME[4]}
    #local Func="${cEmptyLine:0:${#FUNCNAME[@]}-5}${FUNCNAME[4]}"
    Func="$(__Logging_FormatFunction ${type} ${Func} ${Depth})"
    local Source=$(basename ${BASH_SOURCE[4]})
    local LineNo=${BASH_LINENO[3]}

    [ "${Time}" != "" ] && Time=" ${Time}"

    __LOGGING_LAST_LEVEL=$Depth

    retval="[${Color}${Type}${__Logging_ColorOff}${Level}${Time}${cWhite}${Func} (${Source}:${LineNo})${__Logging_ColorOff}] ${msg}" 
}

__Logging_IsInactive () {
    local Script=$(basename ${BASH_SOURCE[3]})
    local Function=${FUNCNAME[3]}

    [[ "${Script}" =~ ${LOGGING_SCRIPTS} && \
	    "${Function}" =~ ${LOGGING_FUNCTIONS} ]] && return 1
    return 0
}

__Logging_InsufficientLevel () {
    local lvl=$1
    local threshold=$2
    (( ${lvl} <= ${threshold} )) && return 1
    return 0
}

__Logging_Msg () {
    local type=$1; local lvl=$2; local msg=$3

    #local Text=$(__Logging_FormatMsg "${type}" ${lvl} "${msg}")
    __Logging_FormatMsg "${type}" ${lvl} "${msg}"; local Text=${retval}
    local Stream=$(__Logging_Stream "${type}")
    #local Depth=${#FUNCNAME[@]}; ((Depth++))
    #__LOGGING_LAST_LEVEL=$Depth

    echo -e "${Text}" >> "${LOGGING_LOGFILE}"
    eval "echo -e \"\$Text\" $Stream"
}

__Logging_MsgCat () {
    local type=$1; local lvl=$2; local msg=$3
    local file=$4; local source=$5; [ "${source}" == "" ] && source="${file}"

    local Stream=$(__Logging_Stream "${type}")
    #local Text=$(__Logging_FormatMsg "${type}" ${lvl} "(content of \"${source}\") ${msg}")
    __Logging_FormatMsg "${type}" ${lvl} "(content of \"${source}\") ${msg}"; local Text=${retval}

    # write to log file & stream
    echo -e -n "${Text}\n"            >> "${LOGGING_LOGFILE}" 
    eval "echo -e -n \"\$Text\\n\"        $Stream"          

    # check if file exists
    [ ! -f "${file}" ] && __Logging_LibError "file \"${file}\" does not exist" && return 0

    # write to log file
    echo -e -n "$__Logging_ColorInfo" >> "${LOGGING_LOGFILE}" 
    cat "${file}"                     >> "${LOGGING_LOGFILE}" 
    echo -e -n "$__Logging_ColorOff"  >> "${LOGGING_LOGFILE}" 

    # write to output stream (stdout/stderr)
    eval "echo -e -n \"$__Logging_ColorInfo\" $Stream"     
    eval "cat \"${file}\"                     $Stream"                         
    eval "echo -e -n \"$__Logging_ColorOff\"  $Stream" 
}

# public functions

eval "${LOGGING_NAMESPACE:1}DebuggingIsActive() { __Logging_DebuggingIsActive \"\$@\"; }"
__Logging_DebuggingIsActive () {
    local lvl=$1

    __Logging_IsInactive && return 1
    __Logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 1
    return 0
}

eval "${LOGGING_NAMESPACE:1}DebugMsg() { __Logging_DebugMsg \"\$@\"; }"
__Logging_DebugMsg () {
    local lvl=$1; local msg=$2

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __Logging_Msg DEBUG ${lvl} "${msg}"
}

eval "${LOGGING_NAMESPACE:1}DebugCat() { __Logging_DebugCat \"\$@\"; }"
__Logging_DebugCat () {
    local lvl=$1; local msg=$2; local file=$3; local source=$4

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __Logging_MsgCat DEBUG ${lvl} "${msg}" "${file}" "${source}"

}

eval "${LOGGING_NAMESPACE:1}DebugLs() { __Logging_DebugLs \"\$@\"; }"
__Logging_DebugLs () {
    local lvl=$1; local msg=$2; local dir=$3

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    [ ! -d "${dir}" ] && \
        __Logging_Msg DEBUG ${lvl} "${msg}" && \
	__Logging_LibError "directory \"${dir}\" does not exist" && return 0

    local tmp_file=$(mktemp)
    [ ! -f "${tmp_file}" ] && \
	__Logging_LibError "cannot create temp file \"${tmp_file}\"" && return 0

    ls -laR "${dir}" > "${tmp_file}"
    __Logging_MsgCat DEBUG ${lvl} "${msg}" "${tmp_file}" "${dir}"
    rm -f -- "${tmp_file}"
}

eval "${LOGGING_NAMESPACE:1}DebugLoggingConfig() { __Logging_DebugLoggingConfig \"\$@\"; }"
__Logging_DebugLoggingConfig () {
    local lvl=$1

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __Logging_Msg DEBUG ${lvl} "LOGGING_NAMESPACE       = $LOGGING_NAMESPACE"
    __Logging_Msg DEBUG ${lvl} "LOGGING_LIB_DIRECTORY   = ${LOGGING_LIB_DIRECTORY}"
    __Logging_Msg DEBUG ${lvl} "LOGGING_STYLE           = $LOGGING_STYLE"
    __Logging_Msg DEBUG ${lvl} "LOGGING_INFO_STD_LEVEL  = $LOGGING_INFO_STD_LEVEL"
    __Logging_Msg DEBUG ${lvl} "LOGGING_DEBUG_STD_LEVEL = $LOGGING_DEBUG_STD_LEVEL"
    __Logging_Msg DEBUG ${lvl} "LOGGING_INFO_LEVEL      = $LOGGING_INFO_LEVEL"
    __Logging_Msg DEBUG ${lvl} "LOGGING_DEBUG_LEVEL     = $LOGGING_DEBUG_LEVEL"
    __Logging_Msg DEBUG ${lvl} "LOGGING_SCRIPTS         = $LOGGING_SCRIPTS"
    __Logging_Msg DEBUG ${lvl} "LOGGING_FUNCTIONS       = $LOGGING_FUNCTIONS"
    __Logging_Msg DEBUG ${lvl} "LOGGING_TIMESTAMP       = $LOGGING_TIMESTAMP"
    __Logging_Msg DEBUG ${lvl} "LOGGING_LOGFILE         = $LOGGING_LOGFILE"
}

# info

eval "${LOGGING_NAMESPACE:1}InfoMsg() { __Logging_InfoMsg \"\$@\"; }"
__Logging_InfoMsg () {
    local nargs=$#; local lvl=${LOGGING_INFO_STD_LEVEL}; local msg=$1
    ((${nargs} == 2)) && lvl=$1 && msg=$2

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __Logging_Msg INFO ${lvl} "${msg}"
}

eval "${LOGGING_NAMESPACE:1}InfoCat() { __Logging_InfoCat \"\$@\"; }"
__Logging_InfoCat () {
    local nargs=$#; local lvl=${LOGGING_INFO_STD_LEVEL}; local msg=$1; local file=$2
    ((${nargs} == 3)) && lvl=$1 && msg=$2; local file=$2

    __Logging_IsInactive && return 0
    __Logging_InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __Logging_MsgCat INFO ${lvl} "${msg}" "${file}"
}

# warn

eval "${LOGGING_NAMESPACE:1}WarnMsg() { __Logging_WarnMsg \"\$@\"; }"
__Logging_WarnMsg () {
    local msg=$1

    __Logging_Msg WARN 0 "${msg}"
}

# error

eval "${LOGGING_NAMESPACE:1}ErrorMsg() { __Logging_ErrorMsg \"\$@\"; }"
__Logging_ErrorMsg () {
    local msg=$1

    __Logging_Msg ERROR 0 "${msg}"
}

eval "${LOGGING_NAMESPACE:1}ErrorCat() { __Logging_ErrorCat \"\$@\"; }"
__Logging_ErrorCat () {
    local msg=$1; local file=$2

    __Logging_MsgCat ERROR 0 "${msg}" "${file}"
}

LOGGING_ISLOADED="yes"

# EOF
