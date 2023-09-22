# file: logging.sh

# requirements: basename, cat, readlink

# - args and return values are lower case
# - local variables are camel case (upper case first letter)
# - local constants are prefixed with 'c'
# - global variables for return values: retval, retval1, retval2, ... 
# - global variable for error return value: reterr

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=.Logging.}"
LOGGING_LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}/logging")

# mutable module options
LOGGING_STYLE="${LOGGING_STYLE:=color}"
LOGGING_INFO_DEFAULT_LEVEL="${LOGGING_INFO_DEFAULT_LEVEL:=1}"
LOGGING_INFO_LEVEL="${LOGGING_INFO_LEVEL:=1}"
LOGGING_DEBUG_DEFAULT_LEVEL="${LOGGING_DEBUG_DEFAULT_LEVEL:=1}"
LOGGING_DEBUG_LEVEL="${LOGGING_DEBUG_LEVEL:=0}"
LOGGING_SCRIPTS="${LOGGING_SCRIPTS:=.*}"
LOGGING_FUNCTONS="${LOGGING_FUNCTIONS:=.*}"
LOGGING_TIMESTAMP="${LOGGING_TIMESTAMP:=date +\"%d.%m.%Y %T\"}" # set this to "echo" to disable all timestamps
LOGGING_LOGFILE="${LOGGING_LOGFILE:=/dev/null}"

# internal helper function
__Logging.InternalError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[1]}); local line=${BASH_LINENO[0]}; local func=${FUNCNAME[1]}
    # colors
    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${LOGGING_LOGFILE}" 
}

#LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
#[ ! -e "${LIB_DIRECTORY}" ] && __Logging.InternalError "lib directory \"${LIB_DIRECTORY}\" does not exist" && exit 1

# checks

[ -z "${LIB_DIRECTORY}" ] && __Logging.InternalError "LIB_DIRECTORY is not defined" && exit 1
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && __Logging.InternalError "logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1

# load library files

# colors 
source "${LOGGING_LIB_DIRECTORY}/_colors.sh"

# load required modules

# global variables

# global constants

# colors


#__Logging_Blue=$(__Colors_GetColor Blue)
#__Logging_Purple=$(__Colors_GetColor Purple)
#__Logging_Yellow=$(__Colors_GetColor Yellow)
#__Logging_Red=$(__Colors_GetColor Red)
#__Logging_BRed=$(__Colors_GetColor BRed)
#__Logging_BWhite=$(__Colors_GetColor BWhite)

__Logging_ColorOff=$(__Colors_GetColor Color_Off)
__Logging_ColorError=$(__Colors_GetColor BRed)
__Logging_ColorWarn=$(__Colors_GetColor Yellow)
__Logging_ColorInfo=$(__Colors_GetColor Blue)
__Logging_ColorDebug=$(__Colors_GetColor Purple)
#__Logging_ColorWarn=${__Logging_Yellow}
#__Logging_ColorInfo=${__Logging_Blue}
#__Logging_ColorDebug=${__Logging_Purple}

# private functions

__Logging_Stream () {
    local type=$1
    # redirect to stderr
    [ "${type}" == "ERROR" ] && echo '>&2' && return 0    
    # no redirection
    echo ""
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
    local msg=$2

    local cWhite=$(__Colors_GetColor BWhite)
    local cEmptyLine="                                      "

    local Color="$(__Logging_TextColor ${type})"
    local Time=$(eval $LOGGING_TIMESTAMP)
    local Type=$(printf '%-5s' "${type}")
    local Func="${cEmptyLine:0:${#FUNCNAME[@]}-5}${FUNCNAME[4]}"
    local Source=$(basename ${BASH_SOURCE[4]})
    local LineNo=${BASH_LINENO[3]}

    [ "${Time}" != "" ] && Time="${Time} "

    echo "[${Color}${Type}${__Logging_ColorOff} ${Time}${cWhite}${Func} (${Source}:${LineNo})${__Logging_ColorOff}] ${msg}" 
}

__Logging.IsInactive () {
    local Script=$(basename ${BASH_SOURCE[3]})
    local Function=${FUNCNAME[3]}

    #echo -n "${Script} ${Function}:" >&2
    [[ "${Script}" =~ ${LOGGING_SCRIPTS} && \
	    "${Function}" =~ ${LOGGING_FUNCTIONS} ]] && return 1
    #echo "supressed" >&2
    return 0
}

# OBSOLETE
__Logging.IsActiveOBSOLETE () {
    local Script=$(basename ${BASH_SOURCE[4]})
    local Function=${FUNCNAME[4]}
    [[ "${Script}" =~ ${LOGGING_SCRIPTS} && \
	    "${Function}" =~ ${LOGGING_FUNCTIONS} ]] && return 0
    return 1
}

__Logging.InsufficientLevel () {
    local lvl=$1
    local threshold=$2
    (( ${lvl} <= ${threshold} )) && return 1
    return 0
}

# OBSOLETE
__Logging.SufficientDebugLevelOBSOLETE () {
    local dlvl=$1
    (( ${dlvl} <= ${LOGGING_DEBUG_LEVEL} )) && return 0
    return 1
#    if (( ${dlvl} <= ${LOGGING_DEBUG_LEVEL} )); then
#        return 0
#    else 
#        return 1
#    fi
}

__Logging_Msg () {
    local type=$1
    local msg=$2

    local Text=$(__Logging_FormatMsg "${type}" "${msg}")
    local Stream=$(__Logging_Stream "${type}")

    #if $(__Logging.IsActive); then
#    if __Logging.IsActive || [ "${type}" == "ERROR" ]; then
    echo -e "${Text}" >> "${LOGGING_LOGFILE}"
    eval "echo -e \"\$Text\" $Stream"
#	 echo -e "$MsgText"  | tee -a "${LOGGING_LOGFILE}"
#    fi
}

__Logging_MsgCat () {
    local type=$1; local msg=$2
    local file=$3; local source=$4; [ "${source}" == "" ] && source="${file}"

#    [[ ! __Logging.IsActive ]] && return 0

    local Stream=$(__Logging_Stream "${type}")
#    local Source=$4
#    if [ -z "$4" ]; then
#	    Source=${file}
#    fi
    local Text=$(__Logging_FormatMsg "${type}" "(content of \"${source}\") ${msg}")

	# check if file exists
    [ ! -f "${file}" ] && __Logging.InternalError "file \"${file}\" does not exist" && return 0
    #if $(__Logging.IsActive); then
#    if __Logging.IsActive; then
    echo -e -n "${Text}\n"          >> "${LOGGING_LOGFILE}" 
    eval "echo -e -n \"\$Text\\n\"        $Stream"          

	#[ ! -f "${file}" ] && _Logging.ErrorMsg "file \"${file}\" does not exist" && return 0

    # write to log file
    echo -e -n "$__Logging_ColorInfo" >> "${LOGGING_LOGFILE}" 
    cat "${file}"                     >> "${LOGGING_LOGFILE}" 
    echo -e -n "$__Logging_ColorOff"  >> "${LOGGING_LOGFILE}" 

    # write to output stream (stdout/stderr)
    eval "echo -e -n \"$__Logging_ColorInfo\" $Stream"     
    eval "cat \"${file}\"                     $Stream"                         
    eval "echo -e -n \"$__Logging_ColorOff\"  $Stream" 
	
 	#echo -e -n "$Text\n"          | tee -a "${LOGGING_LOGFILE}"
        #echo -e -n "$__Logging_Blue"     | tee -a "${LOGGING_LOGFILE}"
        #cat "$3"                         | tee -a "${LOGGING_LOGFILE}"
 	#echo -e -n "$__Logging_ColorOff" | tee -a "${LOGGING_LOGFILE}"
#    fi
}

# helper function to put all public calls at the same stack depth

# OBSOLETE
__Logging.DebuggingIsActiveInnerOBSOLETE () {
    local dlvl=$1
    #$(__Logging.IsActive) && $(__Logging.SufficientDebugLevel ${dlvl}) && return 0
    __Logging.IsActive && ( __Logging.SufficientDebugLevel ${dlvl} ) && return 0
    return 1
}

# public functions

eval "${LOGGING_NAMESPACE:1}DebuggingIsActive() { _Logging.DebuggingIsActive \"\$@\"; }"
_Logging.DebuggingIsActive () {
    local lvl=$1

    __Logging.IsInactive && return 1
    __Logging.InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 1
    return 0
#    __Logging.DebuggingIsActiveInner $1
}

eval "${LOGGING_NAMESPACE:1}DebugMsg() { _Logging.DebugMsg \"\$@\"; }"
_Logging.DebugMsg () {
    local lvl=$1; local msg=$2

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __Logging_Msg DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}"
#    __Logging.SufficientDebugLevel ${dlvl} &&\
#        __Logging_Msg DEBUG "[${dlvl}/${LOGGING_DEBUG_LEVEL}] ${msg}"
#    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
#        __Logging_Msg DEBUG "[$1/$LOGGING_DEBUG_LEVEL] $2"
#    fi
}

eval "${LOGGING_NAMESPACE:1}DebugCat() { _Logging.DebugCat \"\$@\"; }"
_Logging.DebugCat () {
    local lvl=$1; local msg=$2; local file=$3; local source=$4

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    __Logging_MsgCat DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" "${file}" "${source}"

#    __Logging.SufficientDebugLevel ${dlvl} &&\
#        __Logging_MsgCat DEBUG "[${dlvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" "${file}" "${source}"
#    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
#        __Logging_MsgCat DEBUG "[$1/$LOGGING_DEBUG_LEVEL] $2" "$3" "$4"
#    fi
}

eval "${LOGGING_NAMESPACE:1}DebugLs() { _Logging.DebugLs \"\$@\"; }"
_Logging.DebugLs () {
    local lvl=$1; local msg=$2; local dir=$3
    #if (( ${dlvl} <= ${LOGGING_DEBUG_LEVEL} )); then

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

#    if __Logging.SufficientDebugLevel ${dlvl}; then
	# [ ! -d "${dir}" ] && _Logging.ErrorMsg "directory \"${dir}\" does not exist" && return 0
    [ ! -d "${dir}" ] && \
        __Logging_Msg DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" && \
	__Logging.InternalError "directory \"${dir}\" does not exist" && return 0
    local tmp_file=$(mktemp)
    [ ! -f "${tmp_file}" ] && \
	  __Logging.InternalError "cannot create temp file \"${tmp_file}\"" && return 0

#    if ! [ -f "${tmp_file}" ]; then
	  # _Logging.ErrorMsg "cannot create temp file \"${tmp_file}\""
#	  __Logging.InternalError "cannot create temp file \"${tmp_file}\""
#	else
	  #_Logging.DebugMsg 9 "using \"${tmp_file}\" as temp file"
    ls -laR "${dir}" > "${tmp_file}"
    __Logging_MsgCat DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" "${tmp_file}" "${dir}"
    rm -f -- "${tmp_file}"
#	fi
#    fi
}

eval "${LOGGING_NAMESPACE:1}DebugLoggingConfig() { _Logging.DebugLoggingConfig \"\$@\"; }"
_Logging.DebugLoggingConfig () {
    local lvl=$1

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_DEBUG_LEVEL} && return 0

    local LogLvl="[${lvl}/${LOGGING_DEBUG_LEVEL}]"
    #if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
#    if __Logging.SufficientDebugLevel ${dlvl}; then
    __Logging_Msg DEBUG "$LogLvl LOGGING_NAMESPACE     = $LOGGING_NAMESPACE"
    __Logging_Msg DEBUG "$LogLvl LOGGING_LIB_DIRECTORY = ${LOGGING_LIB_DIRECTORY}"
    __Logging_Msg DEBUG "$LogLvl LOGGING_STYLE         = $LOGGING_STYLE"
    __Logging_Msg DEBUG "$LogLvl LOGGING_DEBUG_LEVEL   = $LOGGING_DEBUG_LEVEL"
    __Logging_Msg DEBUG "$LogLvl LOGGING_SCRIPTS       = $LOGGING_SCRIPTS"
    __Logging_Msg DEBUG "$LogLvl LOGGING_FUNCTIONS     = $LOGGING_FUNCTIONS"
    __Logging_Msg DEBUG "$LogLvl LOGGING_TIMESTAMP     = $LOGGING_TIMESTAMP"
    __Logging_Msg DEBUG "$LogLvl LOGGING_LOGFILE       = $LOGGING_LOGFILE"
#    fi
}

# info

eval "${LOGGING_NAMESPACE:1}InfoMsg() { _Logging.InfoMsg \"\$@\"; }"
_Logging.InfoMsg () {
    local nargs=$#; local lvl=${LOGGING_INFO_DEFAULT_LEVEL}; local msg=$1
    ((${nargs} == 2)) && lvl=$1 && msg=$2

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __Logging_Msg INFO "${msg}"
}

eval "${LOGGING_NAMESPACE:1}InfoCat() { _Logging.InfoCat \"\$@\"; }"
_Logging.InfoCat () {
    local nargs=$#; local lvl=${LOGGING_INFO_DEFAULT_LEVEL}; local msg=$1; local file=$2
    ((${nargs} == 3)) && lvl=$1 && msg=$2; local file=$2
#    local lvl=0; local msg=$1; local file=$2

    __Logging.IsInactive && return 0
    __Logging.InsufficientLevel ${lvl} ${LOGGING_INFO_LEVEL} && return 0
    __Logging_MsgCat INFO "${msg}" "${file}"
}

# warn

eval "${LOGGING_NAMESPACE:1}WarnMsg() { _Logging.WarnMsg \"\$@\"; }"
_Logging.WarnMsg () {
    local msg=$1

    __Logging_Msg WARN "${msg}"
}

# error

eval "${LOGGING_NAMESPACE:1}ErrorMsg() { _Logging.ErrorMsg \"\$@\"; }"
_Logging.ErrorMsg () {
    local msg=$1

    __Logging_Msg ERROR "${msg}"
}

eval "${LOGGING_NAMESPACE:1}ErrorCat() { _Logging.ErrorCat \"\$@\"; }"
_Logging.ErrorCat () {
    local msg=$1; local file=$2

    __Logging_MsgCat ERROR "${msg}" "${file}"
}

# EOF
