#!/usr/bin/env bash

# file: yaml.sh

# example showing use of yaml module

LIB_DIRECTORY=$(pwd)/../..

#LOGGING_NAMESPACE="."
#source ${LIB_DIRECTORY}/logging.sh

# use global namespace
YAML_NAMESPACE="."
source ${LIB_DIRECTORY}/yaml.sh

echo "sample1.yaml ---------------------------------------------------"
ParseYamlToShellCode sample1.yaml
eval $(ParseYamlToShellCode sample1.yaml)
for f in $global_flags_ ; do eval echo \$f=\$${f} ; done
echo

echo "sample2.yaml ---------------------------------------------------"
ParseYamlToShellCode sample2.yaml
eval $(ParseYamlToShellCode sample2.yaml)

echo "sample3.yaml ---------------------------------------------------"
ParseYamlToShellCode sample3.yaml
eval $(ParseYamlToShellCode sample3.yaml)

# EOF
