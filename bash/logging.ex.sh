#!/usr/bin/env bash

# file: logging.ex.sh

# example showing use of logging module

# initialize library
source lib.inc.sh
[ -z "$LIB_DIRECTORY" ] && echo "logging.ex.sh: LIB_DIRECTORY not defined, terminating." && exit 1

#LOGGING_DEBUG_LEVEL=3
#LOGGING_MODULES="logging.ex"

# load logging module
# use global namespace
LOGGING_NAMESPACE="."
source ${LIB_DIRECTORY}/logging.inc.sh

ParseLoggingOptions ${@}
DebugLoggingConfig 9

#SetLoggingModuleName logging.ex

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

# EOF
