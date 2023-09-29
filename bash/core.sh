# file: core.sh

# requirements: basename, cat

# checks

[ ! -z "${CORE_ISLOADED}" ] && core_FatalExit "core module already loaded" 1

# options

CORE_LOGFILE="${CORE_LOGFILE:=lib-bash-core-$(basename $0)-$$.log}"
CORE_DEBUG="${CORE_DEBUG:=}"

# private variables

__CORE_LIST_OF_TEMP_DIRS=""
__CORE_LIST_OF_FUSE_MOUNTS=""

# private functions

__core_CleanupOnExitP () {
    __core_FuseUnmountOnExitP
    __core_RemoveTempOnExitP
}

__core_FuseUnmountOnExitP () {
    core_DebugMsg "unmounting ${__CORE_LIST_OF_FUSE_MOUNTS}"
    eval "${__CORE_LIST_OF_FUSE_MOUNTS}"
}

__core_RemoveTempOnExitP () {
    core_DebugMsg "removing temporary directories ${__CORE_LIST_OF_TEMP_DIRS}"
    eval "rm -rf ${__CORE_LIST_OF_TEMP_DIRS}"
}

__core_GetColor () {
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

  eval "echo \"\$$arg\""
}

__core_FmtMsg () {
    local col=$1; local tag=$2; local msg=$3

    local Source=$(basename ${BASH_SOURCE[2]})
    local Line=${BASH_LINENO[1]}
    local Func=${FUNCNAME[2]}

    local cColorOff='\033[0m'; local cWhite='\033[0;37m' 

    local Text="[${col}${tag}${cColorOff}${cWhite} ${Func} (${Source}:${Line})${cColorOff}] ${msg}"

    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

# public functions

core_DebugMsg () {
    local msg="$1"
    local cPurple='\033[0;35m'
    [ -z "${CORE_DEBUG}" ] && return 0
    __core_FmtMsg ${cPurple} "LIBDEBUG" "${msg}"
}

core_WarnMsg () {
    local msg="$1"
    local cYellow='\033[0;33m'
    __core_FmtMsg ${cYellow} "LIBWARN " "${msg}"
}

core_ErrorMsg () {
    local msg="$1"
    local cBRed='\033[1;31m' 
    __core_FmtMsg ${cBRed} "LIBERROR" "${msg}"
}

core_FatalExit () {
    local msg="$1"; local ec=$2
    local cOnRed='\033[41m' 
    __core_FmtMsg ${cOnRed} "LIBFATAL" "${msg}"
    exit ${ec}
}

# check for a list of binaries
#
# returns 0 if all arguments are found in PATH
# returns 1 else
#           [errval] contains a comma separated string of 
#           arguments that are not found in PATH

core_CheckBinaries () {
    errval=""

    for app in "$@"
    do
        if ! hash ${app} 2>/dev/null; then
            errval="${errval},${app}"
        fi
    done
    errval=${errval:1}
    [ ! -z ${errval} ] && return 1
    return 0
}

core_CreateEncryptedTempDir () {
    local password=$1

    [ -z ${password} ] && password=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 64)

    core_CreateTempDir; local ec=$?; local Tempd=$retval
    [ ! $ec -eq 0 ] && return $ec

    local CipherDir=$(mktemp -d -p ${Tempd})
    [ ! -e "${CipherDir}" ] && errval="failed to create temporary cipher directory" && return 1
    local PlainDir=$(mktemp -d -p ${Tempd})
    [ ! -e "${PlainDir}" ] && errval="failed to create temporary plain directory" && return 1
    
    gocryptfs -extpass echo -extpass "${password}" -init "${CipherDir}" > /dev/null; ec=$?
    [ ! $ec -eq 0 ] &&  errval="gocryptfs init failed" && return $ec
    gocryptfs -extpass echo -extpass "${password}" "${CipherDir}" "${PlainDir}" > /dev/null; ec=$?
    [ ! $ec -eq 0 ] &&  errval="gocryptfs mount failed" && return $ec

    __CORE_LIST_OF_FUSE_MOUNTS="${__CORE_LIST_OF_FUSE_MOUNTS}fusermount -u \"${PlainDir}\"; "

    local MasterKeyFile=$(mktemp -p ${Tempd})
    [ ! -e "${PlainDir}" ] && errval="failed to create temporary master key file" && return 1
    echo "${password}" | gocryptfs-xray -dumpmasterkey "${CipherDir}/gocryptfs.conf" > "${MasterKeyFile}"; ec=$?
    [ ! $ec -eq 0 ] &&  errval="gocryptfs master key export failed" && return $ec
    local MasterKey=$(cat "${MasterKeyFile}")
    rm -f ${MasterKeyFile}

    # CAVE: it might not be safe to remove the config file!!
    rm -f "${CipherDir}/gocryptfs.conf" 
    core_DebugMsg "created encrypted temporary directory \"${PlainDir}\""

    retval="${PlainDir}"
    retval1="${CipherDir}"
    retval2="${password}"
    retval3="${MasterKey}"

    return 0
}


# create directory in [base] that will be removed on script exit
# [base] must be a subdirectory of /tmp
#
# returns 0 if the directory was created successfully in [base]
#           [retval] contains the name of the directory
# returns 1 if the directory could not be created in /tmp
#           [errval] contains the error message

core_CreateTempDir () {
    base=$1
    retval=""; errval=""

    [ -z ${base} ] && base="/tmp"

    # create temporary directory and store its name in a variable.
    Tempd=$(mktemp -d -p "${base}")

    # check if the temp directory was created successfully.
    [ ! -e "${Tempd}" ] && errval="failed to create temporary directory" && return 1

    __CORE_LIST_OF_TEMP_DIRS="${__CORE_LIST_OF_TEMP_DIRS} \"${Tempd}\""

    # make sure the temp directory is in /tmp.
    [[ ! "${Tempd}" = /tmp/* ]] && errval="temporary directory not in /tmp" && return 1

    core_DebugMsg "created temporary directory \"${Tempd}\""

    retval="${Tempd}"
    return 0
}

# render a template file: expand variables + preserve formatting
#
# template.txt:
# Username: ${user}
#
# use as follows:
# user="Gregory"; core_RenderTemplate /path/to/template.txt > path/to/expanded_file

core_RenderTemplate() {
    eval "echo \"$(cat $1)\""
}

# module init code

# make sure the temp directories get removed on script exit
trap "exit 1" HUP INT PIPE QUIT TERM
trap "__core_CleanupOnExitP" EXIT
 
CORE_ISLOADED="yes"

# EOF
