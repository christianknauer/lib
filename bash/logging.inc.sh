#!/bin/bash

# file: logging.inc.sh

[ -z "$LIB_DIRECTORY" ] && echo "logging.inc.sh: LIB_DIRECTORY not defined, terminating." && exit 1

# immutable module options
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:=.Logging.}"

# mutable module options
LOGGING_STYLE="${LOGGING_STYLE:=color}"
LOGGING_DEBUG_LEVEL="${LOGGING_DEBUG_LEVEL:=0}"
LOGGING_MODULES="${LOGGING_MODULES:=ALL}"

#_LOGGING_MODULE_DIR=$(dirname "$BASH_SOURCE")

# load required modules

# colors module (use default namespace "Colors.")
source "$LIB_DIRECTORY/colors.inc.sh"

# global variables
LOGGING_MODULE_NAME=$(basename "$0")
LOGGING_FUNCTION_NAME="main"

# global constants

# colors

__Logging_ColorOff=$(Colors.GetColor Color_Off)
__Logging_Blue=$(Colors.GetColor Blue)
__Logging_Purple=$(Colors.GetColor Purple)
__Logging_Yellow=$(Colors.GetColor Yellow)
__Logging_Red=$(Colors.GetColor Red)
__Logging_BRed=$(Colors.GetColor BRed)
__Logging_BWhite=$(Colors.GetColor BWhite)

# private functions

__Logging_Push(){ let __Logging_FunctionStackCtr++;eval "__Logging_FunctionStackItem$__Logging_FunctionStackCtr=\"$1\"";}
__Logging_Pop(){ eval "echo -e \$__Logging_FunctionStackItem$__Logging_FunctionStackCtr;unset __Logging_FunctionStackItem$__Logging_FunctionStackCtr";let __Logging_FunctionStackCtr--;}
#__Logging_Append(){ __Logging_Push "`__Logging_Pop`\n$1";}

__Logging_EnterFunction () {
    __Logging_Push $LOGGING_FUNCTION_NAME
    LOGGING_FUNCTION_NAME=$1
}

__Logging_LeaveFunction () {
    LOGGING_FUNCTION_NAME="`__Logging_Pop`" 
}

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
    local Text_Color="$(__Logging_TextColor $1)"
    local Time_Stamp=$(date +"%d.%m.%Y %T")
    local Level=$(printf '%-5s' "$1")
    if [ "$LOGGING_STYLE" == "color" ]; then
	    echo "[$Text_Color$Level$__Logging_ColorOff $Time_Stamp $__Logging_BWhite$LOGGING_MODULE_NAME ($LOGGING_FUNCTION_NAME)$__Logging_ColorOff] $2" 
    else 
        echo "[$Level $Time_Stamp $LOGGING_MODULE_NAME] $2" 
    fi
}

__Logging_Msg () {
    local MsgText=$(__Logging_FormatMsg "$1" "$2")
    if $(__Logging_DebuggingModule); then
        echo -e "$MsgText" 
    fi
}

__Logging_MsgCat () {
    local Source=$4
    if [ -z "$4" ]; then
	    Source=$3
    fi
    local MsgText=$(__Logging_FormatMsg "$1" "(content of \"$Source\") $2")
    if $(__Logging_DebuggingModule); then
	    echo -e -n "$MsgText\n" # ; cat "$4" 
        if [ "$LOGGING_STYLE" == "color" ]; then
            echo -e -n "$__Logging_Blue" ; cat "$3" ; echo -e -n "$__Logging_ColorOff"
        else 
            cat "$3" 
        fi
    fi
}

__Logging_DebuggingModule () {
    local Scope="$LOGGING_MODULE_NAME"

    if [[ $LOGGING_MODULES == "ALL" ]]; then
	return 0 
    fi
    if [[ $LOGGING_MODULES =~ "$Scope" ]]; then
	return 0
    else 
	return 1
    fi
}

# public functions

eval "${LOGGING_NAMESPACE:1}SetLoggingModuleName() { _Logging.SetLoggingModuleName \"\$@\"; }"
_Logging.SetLoggingModuleName () {
    LOGGING_MODULE_NAME=$1 ; return 1
}

eval "${LOGGING_NAMESPACE:1}DebuggingIsActive() { _Logging.DebuggingIsActive \"\$@\"; }"
_Logging.DebuggingIsActive () {
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
    _Exit () { 
	__Logging_EnterFunction ${FUNCNAME[1]}
	DebugMsg 1 "Exiting ${FUNCNAME[1]}"
	__Logging_LeaveFunction
    }
    if (( $1 <= $LOGGING_DEBUG_LEVEL )); then
	__Logging_EnterFunction ${FUNCNAME[0]}
	local tmp_file=$(mktemp)
	if ! [ -f $tmp_file ]; then
	  _Logging.ErrorMsg "Cannot create temp file ($tmp_file)."
	  __Logging_LeaveFunction
	else
	  _Logging.DebugMsg 9 "Using $tmp_file as temp file."
	  __Logging_LeaveFunction
          ls -laR "$3" > "$tmp_file"
	  DebugCat "$1" "$2" "$tmp_file" "$3"
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
    __Logging_Push $LOGGING_FUNCTION_NAME
    LOGGING_FUNCTION_NAME=${FUNCNAME[0]}
    DebugMsg $1 "LOGGING_NAMESPACE   = $LOGGING_NAMESPACE"
    DebugMsg $1 "LOGGING_MODULE_NAME = $LOGGING_MODULE_NAME"
    DebugMsg $1 "LOGGING_STYLE       = $LOGGING_STYLE"
    DebugMsg $1 "LOGGING_DEBUG_LEVEL = $LOGGING_DEBUG_LEVEL"
    DebugMsg $1 "LOGGING_MODULES     = $LOGGING_MODULES"
    LOGGING_FUNCTION_NAME="`__Logging_Pop`" 
}

_Logging.DebugLoggingConfig 9

# EOF
