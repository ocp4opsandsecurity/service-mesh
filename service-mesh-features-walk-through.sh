#!/bin/bash

########################
# include dependencies
########################
. ./service-mesh-export.sh
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
pe "oc get virtualservices -n $BOOKINFO_PROJECT"   #-- there should be virtual services: bookinfo
pe "oc get destinationrules -n $BOOKINFO_PROJECT"  #-- there should be destination rules: details, ratings, and revies
pe "oc get gateway -n $BOOKINFO_PROJECT"           #-- there should be a gateway: bookinfo-gateway
pe "oc get pods -n $BOOKINFO_PROJECT"              #-- there should be bookinfo pods
p ""

p "Deploy destination rules"
pe "oc apply -n $BOOKINFO_PROJECT -f $BOOKINFO_DEST_RULES_YAML"
pe ""
clear

p "Deploy reviews v2 (check for BLACK Stars)"
pe "oc apply -n $BOOKINFO_PROJECT -f $BOOKINFO_APP_YAML -l app=reviews,version=v2"
pe ""
clear

p "Deploy reviews v3 (check for RED Stars)"
pe "oc apply -n $BOOKINFO_PROJECT -f $BOOKINFO_APP_YAML -l app=reviews,version=v3"
pe ""
clear

p "Deploy Virtual Service (v1)"
pe "oc apply -f- <<EOF
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: details
  spec:
    hosts:
    - details
    http:
    - route:
      - destination:
          host: details
          subset: v1
---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: productpage
  spec:
    hosts:
    - productpage
    http:
    - route:
      - destination:
          host: productpage
          subset: v1
---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: ratings
  spec:
    hosts:
    - ratings
    http:
    - route:
      - destination:
          host: ratings
          subset: v1
---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: reviews
  spec:
    hosts:
    - reviews
    http:
    - route:
      - destination:
          host: reviews
          subset: v1
---
EOF"
pe ""
clear

p "A/B Testing route reviews to v2 (BLACK starts)"
pe "oc apply -f- <<EOF
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: reviews
  spec:
    hosts:
    - reviews
    http:
    - route:
      - destination:
          host: reviews
          subset: v2
EOF"
pe ""
clear

p "Load Balancing: weighted"
pe "oc apply -n $BOOKINFO_PROJECT -f- <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
      weight: 85
    - destination:
        host: reviews
        subset: v3
      weight: 15
EOF"
pe ""
clear

p "Load Balancing: random"
pe "oc apply -n $BOOKINFO_PROJECT -f- <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF"
pe ""
clear



