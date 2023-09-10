#!/bin/bash

# templates

RenderTemplate() {
#
# render a template file
#
# expand variables + preserve formatting
#
# template.txt:
# Username: ${user}
#
# use as follows:
# user="Gregory"
# RenderTemplate /path/to/template.txt > path/to/expanded_file
#
  eval "echo \"$(cat $1)\""
}

# EOF
