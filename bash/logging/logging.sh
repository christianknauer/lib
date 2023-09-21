#!/bin/bash

# file: logging.inc.sh

# requirements: basename, cat, readlink

__Logging.InternalError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[1]}); local line=${BASH_LINENO[0]}; local func=${FUNCNAME[1]}
    # colors
    local ColorOff='\033[0m'; local BRed='\033[1;31m'; local White='\033[0;37m' 
    echo -e "[${BRed}ERROR${ColorOff}${White} ${func} (${source}:${line})${ColorOff}] ${msg}" >&2
}

#LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
#[ ! -e "${LIB_DIRECTORY}" ] && __Logging.InternalError "lib directory \"${LIB_DIRECTORY}\" does not exist" && exit 1

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=.Logging.}"
LOGGING_LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}/logging")

# mutable module options
LOGGING_STYLE="${LOGGING_STYLE:=color}"
LOGGING_DEBUG_LEVEL="${LOGGING_DEBUG_LEVEL:=0}"
LOGGING_SCRIPTS="${LOGGING_SCRIPTS:=.*}"
LOGGING_FUNCTONS="${LOGGING_FUNCTIONS:=.*}"
LOGGING_TIMESTAMP="${LOGGING_TIMESTAMP:=date +\"%d.%m.%Y %T\"}" # set this to "echo" to disable all timestamps
LOGGING_LOGFILE="${LOGGING_LOGFILE:=/dev/null}"

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

__Logging_ColorOff=$(__Colors_GetColor Color_Off)

__Logging_Blue=$(__Colors_GetColor Blue)
__Logging_Purple=$(__Colors_GetColor Purple)
__Logging_Yellow=$(__Colors_GetColor Yellow)
__Logging_Red=$(__Colors_GetColor Red)
__Logging_BRed=$(__Colors_GetColor BRed)
__Logging_BWhite=$(__Colors_GetColor BWhite)

__Logging_ColorError=${__Logging_BRed}
__Logging_ColorWarn=${__Logging_Yellow}
__Logging_ColorInfo=${__Logging_Blue}
__Logging_ColorDebug=${__Logging_Purple}

# private functions

__Logging_Stream () {
    # no redirection
    local Stream=""
    # redirect to stderr
    [ "$1" == "ERROR" ] && echo '>&2' && return 0    
    echo ""
}

__Logging_TextColor () {
    local Text_Color=$__Logging_ColorOff
    if [ "$1" == "INFO" ]; then
	Text_Color=$__Logging_ColorInfo
    elif [ "$1" == "DEBUG" ]; then
	Text_Color=$__Logging_ColorDebug
    elif [ "$1" == "WARN" ]; then
	Text_Color=$__Logging_ColorWarn
    elif [ "$1" == "ERROR" ]; then
	Text_Color=$__Logging_ColorError
#    else 
#	Text_Color=$__Logging_BRed
    fi
    echo "$Text_Color"
}

__Logging_FormatMsg () {
    local SPACES="                                      "
    local Text_Color="$(__Logging_TextColor $1)"
    local Time_Stamp=$(eval $LOGGING_TIMESTAMP)
    local Level=$(printf '%-5s' "$1")
    local LoggingFnNameString="${SPACES:0:${#FUNCNAME[@]}-5}${FUNCNAME[4]}"
    local SourceFile=$(basename ${BASH_SOURCE[4]})
    local LineNo=${BASH_LINENO[3]}

    [ "${Time_Stamp}" != "" ] && Time_Stamp="$Time_Stamp "

    #echo "[$Text_Color$Level$__Logging_ColorOff $Time_Stamp$__Logging_BWhite${SourceFile}:${LineNo} ${LoggingFnNameString}$__Logging_ColorOff] $2" 
    echo "[$Text_Color$Level$__Logging_ColorOff $Time_Stamp$__Logging_BWhite${LoggingFnNameString} (${SourceFile}:${LineNo})$__Logging_ColorOff] $2" 
}

__Logging_Msg () {
    local MsgText=$(__Logging_FormatMsg "$1" "$2")
    local Stream=$(__Logging_Stream "$1")
    if $(__Logging_DebuggingModule); then
	 echo -e "$MsgText" >> "${LOGGING_LOGFILE}"
         eval "echo -e \"\$MsgText\" $Stream"
#	 echo -e "$MsgText"  | tee -a "${LOGGING_LOGFILE}"
    fi
}

__Logging_MsgCat () {
    local Stream=$(__Logging_Stream "$1")
    local file=$3
    local Source=$4
    if [ -z "$4" ]; then
	    Source=$file
    fi
    local MsgText=$(__Logging_FormatMsg "$1" "(content of \"$Source\") $2")
    if $(__Logging_DebuggingModule); then

	echo -e -n "$MsgText\n"          >> "${LOGGING_LOGFILE}" 
	eval "echo -e -n \"\$MsgText\\n\"        $Stream"          

	# check if file exists
	[ ! -f "${file}" ] && __Logging.InternalError "file \"${file}\" does not exist" && return 0
	#[ ! -f "${file}" ] && _Logging.ErrorMsg "file \"${file}\" does not exist" && return 0

	# write to log file
        echo -e -n "$__Logging_Blue"     >> "${LOGGING_LOGFILE}" 
        cat "${file}"                    >> "${LOGGING_LOGFILE}" 
 	echo -e -n "$__Logging_ColorOff" >> "${LOGGING_LOGFILE}" 

	# write to output stream (stdout/stderr)
        eval "echo -e -n \"$__Logging_Blue\"     $Stream"     
        eval "cat \"${file}\"                    $Stream"                         
 	eval "echo -e -n \"$__Logging_ColorOff\" $Stream" 
	
 	#echo -e -n "$MsgText\n"          | tee -a "${LOGGING_LOGFILE}"
        #echo -e -n "$__Logging_Blue"     | tee -a "${LOGGING_LOGFILE}"
        #cat "$3"                         | tee -a "${LOGGING_LOGFILE}"
 	#echo -e -n "$__Logging_ColorOff" | tee -a "${LOGGING_LOGFILE}"
    fi
}

__Logging_DebuggingModule () {
    local Script=$(basename ${BASH_SOURCE[4]})
    local Function=${FUNCNAME[4]}

    if [[ "${Script}" =~ $LOGGING_SCRIPTS ]]; then
   # if [[ $LOGGING_SCRIPTS == "ALL" || $LOGGING_SCRIPTS =~ "$Script" ]]; then
        if [[ "${Function}" =~ $LOGGING_FUNCTIONS ]]; then
        #if [[ $LOGGING_FUNCTIONS == "ALL" || $LOGGING_FUNCTIONS =~ "$Function" ]]; then
   	    return 0
        else 
	    return 1
        fi
    else 
	return 1
    fi
}

# public functions

# helper function to put all public calls at the same stack depth
_Logging.DebuggingIsActiveInner () {
    if $(__Logging_DebuggingModule); then
        if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
	    return 0
        else 
	    return 1
        fi
    else 
	return 1
    fi
}

eval "${LOGGING_NAMESPACE:1}DebuggingIsActive() { _Logging.DebuggingIsActive \"\$@\"; }"
_Logging.DebuggingIsActive () {
    _Logging.DebuggingIsActiveInner $1
}

eval "${LOGGING_NAMESPACE:1}DebugMsg() { _Logging.DebugMsg \"\$@\"; }"
_Logging.DebugMsg () {
    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
        __Logging_Msg DEBUG "[$1/$LOGGING_DEBUG_LEVEL] $2"
    fi
}

eval "${LOGGING_NAMESPACE:1}DebugCat() { _Logging.DebugCat \"\$@\"; }"
_Logging.DebugCat () {
    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
        __Logging_MsgCat DEBUG "[$1/$LOGGING_DEBUG_LEVEL] $2" "$3" "$4"
    fi
}

eval "${LOGGING_NAMESPACE:1}DebugLs() { _Logging.DebugLs \"\$@\"; }"
_Logging.DebugLs () {
    local lvl=$1
    local msg=$2
    local dir=$3
    if (( ${lvl} <= ${LOGGING_DEBUG_LEVEL} )); then
	# [ ! -d "${dir}" ] && _Logging.ErrorMsg "directory \"${dir}\" does not exist" && return 0
	[ ! -d "${dir}" ] && \
          __Logging_Msg DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" && \
	  __Logging.InternalError "directory \"${dir}\" does not exist" && return 0
	local tmp_file=$(mktemp)
	if ! [ -f "${tmp_file}" ]; then
	  # _Logging.ErrorMsg "cannot create temp file \"${tmp_file}\""
	  __Logging.InternalError "cannot create temp file \"${tmp_file}\""
	else
	  #_Logging.DebugMsg 9 "using \"${tmp_file}\" as temp file"
          ls -laR "${dir}" > "${tmp_file}"
          __Logging_MsgCat DEBUG "[${lvl}/${LOGGING_DEBUG_LEVEL}] ${msg}" "${tmp_file}" "${dir}"
	  rm -f -- "${tmp_file}"
	fi
    fi
}

eval "${LOGGING_NAMESPACE:1}InfoMsg() { _Logging.InfoMsg \"\$@\"; }"
_Logging.InfoMsg () {
    __Logging_Msg INFO "$1"
}

eval "${LOGGING_NAMESPACE:1}InfoCat() { _Logging.InfoCat \"\$@\"; }"
_Logging.InfoCat () {
    __Logging_MsgCat INFO "$1" "$2"
}

eval "${LOGGING_NAMESPACE:1}WarnMsg() { _Logging.WarnMsg \"\$@\"; }"
_Logging.WarnMsg () {
    __Logging_Msg WARN "$1"
}

eval "${LOGGING_NAMESPACE:1}ErrorMsg() { _Logging.ErrorMsg \"\$@\"; }"
_Logging.ErrorMsg () {
    __Logging_Msg ERROR "$1"
}

eval "${LOGGING_NAMESPACE:1}ErrorCat() { _Logging.ErrorCat \"\$@\"; }"
_Logging.ErrorCat () {
    __Logging_MsgCat ERROR "$1" "$2"
}

eval "${LOGGING_NAMESPACE:1}DebugLoggingConfig() { _Logging.DebugLoggingConfig \"\$@\"; }"
_Logging.DebugLoggingConfig () {
    local LogLvl="[$1/$LOGGING_DEBUG_LEVEL]"
    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
        __Logging_Msg DEBUG "$LogLvl LOGGING_NAMESPACE     = $LOGGING_NAMESPACE"
        __Logging_Msg DEBUG "$LogLvl LOGGING_LIB_DIRECTORY = ${LOGGING_LIB_DIRECTORY}"
        __Logging_Msg DEBUG "$LogLvl LOGGING_STYLE         = $LOGGING_STYLE"
        __Logging_Msg DEBUG "$LogLvl LOGGING_DEBUG_LEVEL   = $LOGGING_DEBUG_LEVEL"
        __Logging_Msg DEBUG "$LogLvl LOGGING_SCRIPTS       = $LOGGING_SCRIPTS"
        __Logging_Msg DEBUG "$LogLvl LOGGING_FUNCTIONS     = $LOGGING_FUNCTIONS"
        __Logging_Msg DEBUG "$LogLvl LOGGING_TIMESTAMP     = $LOGGING_TIMESTAMP"
        __Logging_Msg DEBUG "$LogLvl LOGGING_LOGFILE       = $LOGGING_LOGFILE"
    fi
}

# EOF
