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

LOGGING_TIMESTAMP=echo
# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# include local files

source subscript.sh

# functions

# main
USAGE="[ -I LOGGING_INFO_LEVEL -D LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE ]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file
CORE_LOGFILE="${LOGGING_LOGFILE}"

DebugLoggingConfig 9

TestFn4 () {
	InfoMsg "inside info"
}


TestFn2 () {
	InfoMsg "inside info"
        TestFn3
        TestFn4
        TestFn4
        TestFn4
        DebugMsg 1 "inside debug"
}

TestFn () {
	InfoMsg "inside info"
        TestFn2
}
DebugMsg 1 "debug"
DebugLs 2 "ls ." .
DebugLs 2 "ls nonexistent" nonexistent 
DebugCat 2 "cat data.txt" data.txt
DebugCat 3 "cat nonexistent" nonexistent
InfoMsg "info default lvl"
InfoMsg 2 "info lvl 2"
WarnMsg "warn"
ErrorMsg "error"
InfoCat "InfoCat data.txt" data.txt
InfoCat 2 "cat nonexistent" nonexistent
if $(DebuggingIsActive 2); then
  InfoMsg "debugging is active"
else
  InfoMsg "debugging is not active"
fi
TestFn
TestFn4

exit 0

# EOF
