#!/usr/bin/env bash

# file: colors.ex.sh

# example showing use of colors module

source lib.inc.sh

# use global namespace
COLORS_NAMESPACE="."
source ${LIB_DIRECTORY}/colors.inc.sh

echo -e "This $(GetColor BWhite)is  a test $(GetColor Color_Off) of colors"

# EOF
