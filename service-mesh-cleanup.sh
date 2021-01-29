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

pe "oc delete project ${BOOKINFO_PROJECT_NAME}"
pe "oc delete project ${CONTROL_PLANE_PROJECT_NAME}"
pe "oc delete user ${BOOKINFO_SERVICE_MESH_USER_NAME}"

########################
# include the install
########################
. ./service-mesh-export.sh
