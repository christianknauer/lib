#!/bin/bash

# file: temp.sh

# check required modules

# core
[ -z "${CORE_ISLOADED}" ] && echo -e "FATAL ERROR temp module ($(basename $0)): core module not loaded" >&2 && exit 1
# import LibError from core module as __Temp_LibError
eval "__Temp_LibError () { ${CORE_NAMESPACE:1}LibError \"\$@\"; }"

# logging
[ -z "${LOGGING_ISLOADED}" ] && __Temp_LibError "FATAL: logging module not loaded" && exit 1

# module can only be loaded once
[ ! -z "${TEMP_ISLOADED}" ] && __Temp_LibError "FATAL: temp module already loaded (namespace ${TEMP_NAMESPACE})" && exit 1

# module options

TEMP_NAMESPACE="${TEMP_NAMESPACE:=.Temp.}"

# global variables

__TEMP_LIST_OF_TEMP_DIRS=""

# global constants

# private functions

__Temp_CleanupTempOnExit () {
    #local TEMPD=$1
    #echo "${__TEMP_LIST_OF_TEMP_DIRS}"
    #DebugMsg 3 "removing temporary directory \"${TEMPD}\""; rm -rf "${TEMPD}"
    DebugMsg 3 "removing temporary directories ${__TEMP_LIST_OF_TEMP_DIRS}"
    eval "rm -rf ${__TEMP_LIST_OF_TEMP_DIRS}"
}

# public functions

eval "${TEMP_NAMESPACE:1}CreateTempDir() { __Temp_CreateTempDir \"\$@\"; }"
__Temp_CreateTempDir () {

    # create temporary directory and store its name in a variable.
    retval=$(mktemp -d)

    # check if the temp directory was created successfully.
    [ ! -e "${retval}" ] && retval="failed to create temporary directory" && return 1

    # make sure the temp directory is in /tmp.
    [[ ! "${retval}" = /tmp/* ]] && retval="temporary directory not in /tmp" && return 1

#    # make sure the temp directory gets removed on script exit.
#    trap "exit 1" HUP INT PIPE QUIT TERM
#    #trap "__Temp_CleanupTempOnExit \"${retval}\"" EXIT
#    trap "__Temp_CleanupTempOnExit" EXIT

    DebugMsg 3 "created temporary directory \"${retval}\""

    __TEMP_LIST_OF_TEMP_DIRS="${__TEMP_LIST_OF_TEMP_DIRS} \"${retval}\""
    return 0
}

# make sure the temp directories get removed on script exit
trap "exit 1" HUP INT PIPE QUIT TERM
trap "__Temp_CleanupTempOnExit" EXIT

TEMP_LOADED="yes"

# EOF
