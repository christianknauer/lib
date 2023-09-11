#!/usr/bin/env bash

# file: logging.ex.sh

# example showing use of logging module

source lib.inc.sh

source ${LIB_DIRECTORY}/logging.inc.sh

LOGGING_LEVEL=3
LOGGING_MODULES="logging.ex"

LoggingModuleName logging.ex

InfoMsg "code starting"

DebugLoggingConfig 2

# EOF
