#!/usr/bin/env bash

# file: options.ex.sh

# example showing use of options module

source lib.inc.sh

LOGGING_NAMESPACE="."
source ${LIB_DIRECTORY}/logging.inc.sh

# use global namespace
OPTIONS_NAMESPACE="."
source ${LIB_DIRECTORY}/options.inc.sh

USAGE="-u USER_NAME -d DATABASE -p PASS -s SID [ -a START_DATE_TIME ]"
ParseOptions "${USAGE}" ${@}

echo -u=${USER_NAME}
echo -d=${DATABASE}
echo -p=${PASS}
echo -s=${SID}
echo -a=${START_DATE_TIME}

# EOF
