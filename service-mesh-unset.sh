#!/bin/bash

########################
# include the magic
########################
. ./demo-magic.sh -n

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=400

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${BLACK}➜ ${CYAN}\W "

# text color
DEMO_CMD_COLOR=$BLACK


# hide the evidence
clear

pe "unset MAISTRA_BRANCH"
pe "unset BOOKINFO_PROJECT"
pe "unset BOOKINFO_APP_URL"
pe "unset BOOKINFO_DEST_RULES_ALL_URL"
pe "unset BOOKINFO_VIRTUAL_SERVICE_V1_URL"
pe "unset BOOKINFO_GATEWAY_URL"
pe "unset CONTROL_PROJECT"

