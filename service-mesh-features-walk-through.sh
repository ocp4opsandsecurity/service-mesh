#!/bin/bash

########################
# include the magic
########################
. ./demo-magic.sh


########################
# Configure the options
########################
#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=100

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

p "Verify Deployment"
pe "oc get virtualservices"   #-- there should be virtual services: bookinfo
pe "oc get destinationrules"  #-- there should be destination rules: details, ratings, and revies
pe "oc get gateway"           #-- there should be a gateway: bookinfo-gateway
pe "oc get pods"              #-- there should be bookinfo pods
p ""