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

pe "export MAISTRA_BRANCH=maistra-2.0"
pe "exprot BOOKINFO_PROJECT=bookinfo"
pe "export BOOKINFO_APP_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/platform/kube/bookinfo.yaml"
pe "export BOOKINFO_DEST_RULES_ALL_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/destination-rule-all-mtls.yaml"
pe "export BOOKINFO_GATEWAY_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/bookinfo-gateway.yaml"
pe "export BOOKINFO_VIRTUAL_SERVICE_V1_URL=https://github.com/maistra/istio/raw/${MAISTRA_BRANCH}/samples/bookinfo/networking/virtual-service-all-v1.yaml"
pe "export CONTROL_PROJECT=istio-system"
