# file: _colors.sh
#
# used by: logging.sh

# global variables

# global constants

# private functions

__Colors_GetColor () {
  local arg=$1
  # Color escape codes

  # Off
  local Color_Off='\033[0m'       # Text Reset

  # Regular 
  local Black='\033[0;30m'        # Black
  local Red='\033[0;31m'          # Red
  local White='\033[0;37m'        # White
  local Green='\033[0;32m'        # Green
  local Yellow='\033[0;33m'       # Yellow
  local Blue='\033[0;34m'         # Blue
  local Purple='\033[0;35m'       # Purple
  local Cyan='\033[0;36m'         # Cyan

  # Bold
  local BBlack='\033[1;30m'       # Black
  local BRed='\033[1;31m'         # Red
  local BGreen='\033[1;32m'       # Green
  local BYellow='\033[1;33m'      # Yellow
  local BBlue='\033[1;34m'        # Blue
  local BPurple='\033[1;35m'      # Purple
  local BCyan='\033[1;36m'        # Cyan
  local BWhite='\033[1;37m'       # White

  # Underline
  local UBlack='\033[4;30m'       # Black
  local URed='\033[4;31m'         # Red
  local UGreen='\033[4;32m'       # Green
  local UYellow='\033[4;33m'      # Yellow
  local UBlue='\033[4;34m'        # Blue
  local UPurple='\033[4;35m'      # Purple
  local UCyan='\033[4;36m'        # Cyan
  local UWhite='\033[4;37m'       # White

  # Background
  local On_Black='\033[40m'       # Black
  local On_Red='\033[41m'         # Red
  local On_Green='\033[42m'       # Green
  local On_Yellow='\033[43m'      # Yellow
  local On_Blue='\033[44m'        # Blue
  local On_Purple='\033[45m'      # Purple
  local On_Cyan='\033[46m'        # Cyan
  local On_White='\033[47m'       # White

  # High Intensity
  local IBlack='\033[0;90m'       # Black
  local IRed='\033[0;91m'         # Red
  local IGreen='\033[0;92m'       # Green
  local IYellow='\033[0;93m'      # Yellow
  local IBlue='\033[0;94m'        # Blue
  local IPurple='\033[0;95m'      # Purple
  local ICyan='\033[0;96m'        # Cyan
  local IWhite='\033[0;97m'       # White

  # Bold High Intensity
  local BIBlack='\033[1;90m'      # Black
  local BIRed='\033[1;91m'        # Red
  local BIGreen='\033[1;92m'      # Green
  local BIYellow='\033[1;93m'     # Yellow
  local BIBlue='\033[1;94m'       # Blue
  local BIPurple='\033[1;95m'     # Purple
  local BICyan='\033[1;96m'       # Cyan
  local BIWhite='\033[1;97m'      # White

  # High Intensity backgrounds
  local On_IBlack='\033[0;100m'   # Black
  local On_IRed='\033[0;101m'     # Red
  local On_IGreen='\033[0;102m'   # Green
  local On_IYellow='\033[0;103m'  # Yellow
  local On_IBlue='\033[0;104m'    # Blue
  local On_IPurple='\033[0;105m'  # Purple
  local On_ICyan='\033[0;106m'    # Cyan
  local On_IWhite='\033[0;107m'   # White

  [ ! "$LOGGING_STYLE" == "color" ] && echo "" && return 0

  eval "echo \"\$$arg\""
}

# EOF
