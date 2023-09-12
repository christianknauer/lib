#!/bin/bash

# file: options.inc.sh

[ -z "$LOGGING_NAMESPACE" ] && echo "options.inc.sh: logging module not available, terminating." && exit 1

# module options

OPTIONS_NAMESPACE="${OPTIONS_NAMESPACE:=.Options.}"

# global variables

# global constants

# private functions

function __Options_get_variable_name_for_option {
    local OPT_DESC=${1}
    local OPTION=${2}
    local VAR=$(echo ${OPT_DESC} | sed -e "s/.*\[\?-${OPTION} \([A-Z_]\+\).*/\1/g" -e "s/.*\[\?-\(${OPTION}\).*/\1FLAG/g")

    if [[ "${VAR}" == "${1}" ]]; then
        echo ""
    else
        echo ${VAR}
    fi
}

function __Options_check_for_required {
    local OPT_DESC=${1}
    local REQUIRED=$(__Options_get_required "${OPT_DESC}" | sed -e "s/\://g")
    while test -n "${REQUIRED}"; do
        OPTION=${REQUIRED:0:1}
        VARNAME=$(__Options_get_variable_name_for_option "${OPT_DESC}" "${OPTION}")
                #[ -z "${!VARNAME}" ] && printf "ERROR: %s\n" "Option -${OPTION} must been set." && __Options_usage
		if [ -z "${!VARNAME}" ]; then
			_Logging.ErrorMsg "Option -${OPTION} must been set."
			__Options_usage
		fi
        REQUIRED=${REQUIRED:1}
    done
}

function __Options_get_input_for_getopts {
    local OPT_DESC=${1}
    echo ${OPT_DESC} | sed -e "s/\([a-zA-Z]\) [A-Z_]\+/\1:/g" -e "s/[][ -]//g"
}

#function __Options_get_optional {
#    local OPT_DESC=${1}
#    echo ${OPT_DESC} | sed -e "s/[^[]*\(\[[^]]*\]\)[^[]*/\1/g" -e "s/\([a-zA-Z]\) [A-Z_]\+/\1:/g" -e "s/[][ -]//g"
#}

function __Options_get_required {
    local OPT_DESC=${1}
    echo ${OPT_DESC} | sed -e "s/\([a-zA-Z]\) [A-Z_]\+/\1:/g" -e "s/\[[^[]*\]//g" -e "s/[][ -]//g"
}

function __Options_usage {
    printf "Usage:\n\t%s\n" "${0} ${OPT_DESC}"
    exit 10
}

# public functions

eval "${OPTIONS_NAMESPACE:1}ParseOptions() { _Options.ParseOptions \"\$@\"; }"
function _Options.ParseOptions {
    local OPT_DESC=${1}
    local INPUT=$(__Options_get_input_for_getopts "${OPT_DESC}")

    shift
    while getopts ${INPUT} OPTION ${@};
    do
        [ ${OPTION} == "?" ] && __Options_usage
        VARNAME=$(__Options_get_variable_name_for_option "${OPT_DESC}" "${OPTION}")
            [ "${VARNAME}" != "" ] && eval "${VARNAME}=${OPTARG:-true}" # && printf "\t%s\n" "* Declaring ${VARNAME}=${!VARNAME} -- OPTIONS='$OPTION'"
    done

    __Options_check_for_required "${OPT_DESC}"

}

# EOF
