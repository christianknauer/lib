#!/bin/bash

# file: temp.inc.sh

# module options

TEMP_NAMESPACE="${TEMP_NAMESPACE:=.Temp.}"

# global variables

# global constants

# private functions

_Temp.CleanupTempOnExit () {
    local TEMPD=$1
    DebugMsg 3 "removing temporary directory \"${TEMPD}\""; rm -rf "${TEMPD}"
}

# public functions

eval "${TEMP_NAMESPACE:1}CreateTempDir() { _Temp.CreateTempDir \"\$@\"; }"
_Temp.CreateTempDir () {

    # create temporary directory and store its name in a variable.
    retval=$(mktemp -d)

    # check if the temp directory was created successfully.
    [ ! -e "${retval}" ] && retval="failed to create temporary directory" && return 1

    # make sure the temp directory is in /tmp.
    [[ ! "${retval}" = /tmp/* ]] && retval="temporary directory not in /tmp" && return 1

    # make sure the temp directory gets removed on script exit.
    trap "exit 1" HUP INT PIPE QUIT TERM
    trap "_Temp.CleanupTempOnExit \"${retval}\"" EXIT

    DebugMsg 3 "created temporary directory \"${retval}\""

    return 0
}



# EOF
