#!/bin/bash

########################
# include dependencies
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

p "List the running pods"
pe "oc get pods -n bookinfo"
pe ""
clear

p "List the routest to the tools"
pe "oc get route -n istio-system"
pe ""
clear

p "Set gateway url"
pe "export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')"
pe ""
clear

p "Print gateway url to the screen"
pe "echo http://${GATEWAY_URL}/productpage"
pe ""
clear

p "Deploy reviews v2 virtual service (Black Stars)"
pe "ococ apply -f ./traffic-management/virtual-service-reviews-v2.yaml"
pe ""
clear

p "Deploy reviews v3 virtual service (Red Stars)"
pe "ococ apply -f ./traffic-management/virtual-service-reviews-v3.yaml"
pe ""
clear

p "Weighted Load Balancing"
pe "oc apply -f ./traffic-management/weighted-v1-80-v3-20.yaml"
pe ""
clear

p "Header Routing"
pe "oc apply -f ./traffic-management/headers-bill-fred.yaml"
pe ""
clear
