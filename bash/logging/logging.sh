#!/bin/bash

# file: logging.inc.sh

[ -z "${LIB_DIRECTORY}" ] && echo "$0 (logging lib) ERROR: LIB_DIRECTORY is not defined, terminating" && exit 1
LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
[ ! -e "${LIB_DIRECTORY}" ] && echo "$0 (logging lib) ERROR: lib directory \"${LIB_DIRECTORY}\" does not exist" && exit 1

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=.Logging.}"
LOGGING_LIB_DIRECTORY="${LIB_DIRECTORY}/logging"

# mutable module options
LOGGING_STYLE="${LOGGING_STYLE:=color}"
LOGGING_DEBUG_LEVEL="${LOGGING_DEBUG_LEVEL:=0}"
LOGGING_SCRIPTS="${LOGGING_SCRIPTS:=ALL}"
LOGGING_FUNCTONS="${LOGGING_FUNCTIONS:=ALL}"
# set this to "echo" to disable all timestamps
LOGGING_TIMESTAMP="${LOGGING_TIMESTAMP:=date +\"%d.%m.%Y %T\"}"
LOGGING_LOGFILE="${LOGGING_LOGFILE:=/dev/null}"

# load library files

[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && echo "$0 (logging lib) ERROR: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1

# colors 
# colors module (use default namespace "Colors.")
# source "$LIB_DIRECTORY/colors.inc.sh"
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

# private functions

__Logging_TextColor () {
    local Text_Color=$__Logging_ColorOff
    if [ "$1" == "INFO" ]; then
	Text_Color=$__Logging_Blue
    elif [ "$1" == "DEBUG" ]; then
	Text_Color=$__Logging_Purple
    elif [ "$1" == "WARN" ]; then
	Text_Color=$__Logging_Yellow
    elif [ "$1" == "ERROR" ]; then
	Text_Color=$__Logging_Red
    else 
	Text_Color=$__Logging_BRed
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
    if [ "$LOGGING_STYLE" == "color" ]; then
	    echo "[$Text_Color$Level$__Logging_ColorOff $Time_Stamp $__Logging_BWhite${SourceFile}:${LineNo} ${LoggingFnNameString}$__Logging_ColorOff] $2" 
    else 
        echo "[$Level $Time_Stamp ${}$LoggingFnNameString] $2" 
    fi
}

__Logging_Msg () {
    local MsgText=$(__Logging_FormatMsg "$1" "$2")
    if $(__Logging_DebuggingModule); then
        echo -e "$MsgText" | tee -a "${LOGGING_LOGFILE}"
    fi
}

__Logging_MsgCat () {
    local Source=$4
    if [ -z "$4" ]; then
	    Source=$3
    fi
    local MsgText=$(__Logging_FormatMsg "$1" "(content of \"$Source\") $2")
    if $(__Logging_DebuggingModule); then
	echo -e -n "$MsgText\n" | tee -a "${LOGGING_LOGFILE}"
        if [ "$LOGGING_STYLE" == "color" ]; then
            echo -e -n "$__Logging_Blue"     | tee -a "${LOGGING_LOGFILE}"
	    cat "$3"                         | tee -a "${LOGGING_LOGFILE}"
 	    echo -e -n "$__Logging_ColorOff" | tee -a "${LOGGING_LOGFILE}"
        else 
            cat "$3" | tee -a "${LOGGING_LOGFILE}"
        fi
    fi
}

__Logging_DebuggingModule () {
    local Script=$(basename ${BASH_SOURCE[4]})
    local Function=${FUNCNAME[4]}

    if [[ $LOGGING_SCRIPTS == "ALL" || $LOGGING_SCRIPTS =~ "$Script" ]]; then
        if [[ $LOGGING_FUNCTIONS == "ALL" || $LOGGING_FUNCTIONS =~ "$Function" ]]; then
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
    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
	local tmp_file=$(mktemp)
	if ! [ -f $tmp_file ]; then
	  _Logging.ErrorMsg "Cannot create temp file ($tmp_file)."
	else
	  _Logging.DebugMsg 9 "Using $tmp_file as temp file."
          ls -laR "$3" > "$tmp_file"
          __Logging_MsgCat DEBUG "[$1/$LOGGING_DEBUG_LEVEL] $2" "$tmp_file" "$3"
	  rm -f -- "$tmp_file"
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
