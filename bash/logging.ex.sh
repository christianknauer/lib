#!/usr/bin/env bash

# file: logging.ex.sh

# example showing use of logging module

# initialize library
source lib.inc.sh
[ -z "$LIB_DIRECTORY" ] && echo "logging.ex.sh: LIB_DIRECTORY not defined, terminating." && exit 1

# load logging module (use global namespace)
LOGGING_NAMESPACE="."; source ${LIB_DIRECTORY}/logging.inc.sh
# load options module (use default namespace "Options.")
source ${LIB_DIRECTORY}/options.inc.sh

# functions

ParseOptions () {
    USAGE="[ -d LOGGING_DEBUG_LEVEL ]"
    Options.ParseOptions "${USAGE}" ${@}
}

# main

ParseOptions ${@}
DebugLoggingConfig 9

TestFn () {
	InfoMsg "inside info"
}
DebugMsg 2 "debug"
DebugLs 2 "debugls" .
DebugCat 2 "debugcat" lib.inc.sh
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
