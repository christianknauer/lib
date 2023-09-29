# file: core.sh

# requirements: basename, cat

# checks

[ ! -z "${CORE_ISLOADED}" ] && core_LibError "FATAL: core module already loaded" && exit 1

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
    core_LibDebug "unmounting ${__CORE_LIST_OF_FUSE_MOUNTS}"
    eval "${__CORE_LIST_OF_FUSE_MOUNTS}"
}

__core_RemoveTempOnExitP () {
    core_LibDebug "removing temporary directories ${__CORE_LIST_OF_TEMP_DIRS}"
    eval "rm -rf ${__CORE_LIST_OF_TEMP_DIRS}"
}

# public functions

core_LibDebug () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[1]}); local line=${BASH_LINENO[0]}; local func=${FUNCNAME[1]}

    local cColorOff='\033[0m'; local cPurple='\033[0;35m'; local cWhite='\033[0;37m' 

    local Text="[${cPurple}LIBDEBUG${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"
    [ -z "${CORE_DEBUG}" ] && return 0
    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
}

core_LibError () {
    local msg=$1; local source=$(basename ${BASH_SOURCE[2]}); local line=${BASH_LINENO[1]}; local func=${FUNCNAME[2]}

    local cColorOff='\033[0m'; local cBRed='\033[1;31m'; local cWhite='\033[0;37m' 

    local Text="[${cBRed}LIBERROR${cColorOff}${cWhite} ${func} (${source}:${line})${cColorOff}] ${msg}"

    echo -e "${Text}" >&2; echo -e "${Text}" >> "${CORE_LOGFILE}" 
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
    core_LibDebug "created encrypted temporary directory \"${PlainDir}\""

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

    core_LibDebug "created temporary directory \"${Tempd}\""

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
