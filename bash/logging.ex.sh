#!/usr/bin/env bash

# file: logging.ex.sh

# example showing use of logging module

# initialize library
source lib.inc.sh
[ -z "$LIB_DIRECTORY" ] && echo "logging.ex.sh: LIB_DIRECTORY not defined, terminating." && exit 1

# load logging module

# use global namespace
LOGGING_NAMESPACE="."
LOGGING_DEBUG_LEVEL=11
#LOGGING_MODULES="logging.ex"
source ${LIB_DIRECTORY}/logging.inc.sh

#DebugLoggingConfig 2

#SetLoggingModuleName logging.ex

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

# EOF
