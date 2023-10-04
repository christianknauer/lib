# file: temp.sh

LIB_DIRECTORY=$(pwd)/../..

# checks
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1

# load modules (if not already loaded)

# core
[ -z "${CORE_ISLOADED}" ] && source "${LIB_DIRECTORY}/core.sh"

# main

user="First"
core_RenderTemplate template.txt > expanded_template.txt
cat expanded_template.txt

user="Second"
VARWITHDEFAULT="user specified"
core_RenderTemplate template.txt > expanded_template.txt
cat expanded_template.txt

# EOF
