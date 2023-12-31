#!/usr/bin/env bash

# file: test.sh

# example showing use of logging module

# initialize library

LIB_DIRECTORY=$(pwd)/../..

# load logging module 
source "${LIB_DIRECTORY}/logging.sh"

LOGGING_TIMESTAMP=echo
# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# include local files

source subscript.sh

# functions

# main
USAGE="[ -I LOGGING_INFO_LEVEL -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE -D CORE_DEBUG]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file
CORE_LOGFILE="${LOGGING_LOGFILE}"

__logging_DebugConfig

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
InfoCat 2 "InfoCat 2 nonexistent" nonexistent
if $(DebuggingIsActive 2); then
  InfoMsg "debugging is active"
else
  InfoMsg "debugging is not active"
fi
TestFn
TestFn4
InfoMsg 99 "info lvl 99"
DebugMsg 99 "debug lvl 99"

core_CheckBinaries cat openssl find; ec=$?; missing=${retval}
[ ! $ec -eq 0 ] && ErrorMsg "the following binaries are missing: ${missing}" # && exit 1

exit 0

# EOF
