#!/usr/bin/env bash

# file: yaml.sh

# always run this, even when sourced
# CAVE: this breaks ble.sh completion
#(return 0 2>/dev/null) && $(pwd)/$(basename $BASH_SOURCE) "$@" ; (return 0 2>/dev/null) && return

# define bash lib dir
LIB_DIRECTORY=$(pwd)/../..
LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
[ ! -e "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR ($(basename $0)): LIB_DIRECTORY \"${LIB_DIRECTORY}\" not found" >&2 && exit 1

# application specific exit code (silence warn message)
__core_CleanUpOnExitHookP () { : ; }

# ---------------------------------------------------------
__Usage () {

    local ScriptName=$(basename ${0})
 
    echo "Usage: ${ScriptName} [COMMAND] [GLOBAL OPTIONS] filename"
    echo
    echo ""
    echo "Global options:"
    echo ""
    echo "            -d : debug level (int)"
    echo "            -D : core debug enabled (flag)"
    echo "            -i : info level (int)"
    echo "            -L : logfile name (string)"
	
    exit 0
}

__ParseOptions () {
    local AllArgs=$@

    local Option
 
    # get global options
    while getopts "hDd:i:L:" Option; do
       case ${Option} in
          d) export LOGGING_DEBUG_LEVEL=${OPTARG}
	  ;;
          i) export LOGGING_INFO_LEVEL=${OPTARG}
	  ;;
          L) export LOGGING_LOGFILE=${OPTARG}
	  ;;
          D) export CORE_DEBUG=1
	  ;;
          h) __Usage
	  ;;
       esac
    done
    shift $((OPTIND - 1))
    RestArgs=$@

    InputFileName=${1:-config.yaml}
}

# ---------------------------------------------------------
# parse command options
InputFileName=
#[ -z "${1}" ]     && __Usage && exit 0
__ParseOptions $@ || __Usage 

# ---------------------------------------------------------
# load logging module 
# log library errors to app log file
export CORE_LOGFILE="${LOGGING_LOGFILE:-/dev/null}"
[ -z "${LOGGING_ISLOADED}" ] && source "${LIB_DIRECTORY}/logging.sh"
__logging_DebugConfig

# load yaml module
YAML_NAMESPACE="."
source ${LIB_DIRECTORY}/yaml.sh

# ---------------------------------------------------------
[ ! -f "${InputFileName}" ] && ErrorMsg "cannot open input file \"${InputFileName}\"" && exit 1

InfoMsg 1 "reading config from \"${InputFileName}\""

ParseYamlToShellCode ${InputFileName} | \
    while read i; do
	left=${i%=*}
	right=${i#*=}
	# this filters internal entries (trailing _)
	[[ ! ${left} =~ _$ ]] && echo "export ${left^^}=$right"
    done

#eval $(ParseYamlToShellCode sample1.yaml)
#for f in $global_flags_ ; do eval echo \$f=\$${f} ; done

# EOF
