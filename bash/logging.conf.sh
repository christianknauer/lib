#!/bin/bash

# file: logging.config

# logging options
export LOGGING_STYLE_LOG="${LOGGING_STYLE_LOG:=color}"
export LOGGING_LEVEL_DEBUG="${LOGGING_LEVEL_DEBUG:=0}"
export LOGGING_LEVEL_SCOPE="${LOGGING_LEVEL_SCOPE:=}"

# display logging configuration
DebugLoggingConfig () {
    DebugMsg $1 "logging configuration:"
    DebugMsg $1 "LOGGING_STYLE_LOG   = $LOGGING_STYLE_LOG"
    DebugMsg $1 "LOGGING_LEVEL_DEBUG = $LOGGING_LEVEL_DEBUG"
    DebugMsg $1 "LOGGING_LEVEL_SCOPE = $LOGGING_LEVEL_SCOPE"
}

# EOF
