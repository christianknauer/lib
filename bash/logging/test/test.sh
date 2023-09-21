#!/usr/bin/env bash

# file: test.sh

# example showing use of logging module

# initialize library

LIB_DIRECTORY=$(pwd)/../..

# load logging module (use global namespace)
LOGGING_LIB_DIRECTORY="${LIB_DIRECTORY}/logging"
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && echo "$0: ERROR: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1
LOGGING_NAMESPACE="." source "${LOGGING_LIB_DIRECTORY}/logging.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize logging lib" && exit $ec

# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# include local files

source subscript.sh

# functions

# main
USAGE="[ -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE ]"
Options.ParseOptions "${USAGE}" ${@}

DebugLoggingConfig 9

TestFn2 () {
	InfoMsg "inside info"
        TestFn3
}

TestFn () {
	InfoMsg "inside info"
        TestFn2
}
DebugMsg 2 "debug"
DebugLs 2 "ls ." .
DebugLs 2 "ls nonexistent" nonexistent 
DebugCat 2 "cat data.txt" data.txt
DebugCat 2 "cat nonexistent" nonexistent
InfoMsg "info"
WarnMsg "warn"
ErrorMsg "error"
if $(DebuggingIsActive 2); then
  InfoMsg "debugging is active"
else
  InfoMsg "debugging is not active"
fi
TestFn

exit 0

# EOF
