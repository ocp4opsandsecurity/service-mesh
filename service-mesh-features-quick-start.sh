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
TYPE_SPEED=150

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

export CONTROL_PLANE_NAMESPACE=istio-system
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_MESH_USER=bookinfo-mesh-user
export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export GATEWAY_CONFIG=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml

# Deploy ElasticSearch Operator
p "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elasticsearch-subscription
  namespace: openshift-operators
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: elasticsearch-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF"

p "Deploy Jaeger Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product-subscription
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: jaeger-operator.v1.20.2
EOF"

p "Deploy Kiali Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kiali-ossm
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kiali-ossm
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: kiali-operator.v1.24.4
EOF"

p "Deploy Service Mesh Operator"
p "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: servicemeshoperator.v2.0.1.1
EOF"

p "Give the operators time to come up"
pe "sleep 20"

p "Create control plane namespace"
pe "oc new-project $CONTROL_PLANE_NAMESPACE"

p "Deploy Tools"
pe "oc apply -n $CONTROL_PLANE_NAMESPACE -f- <<EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: ${CONTROL_PLANE_NAMESPACE}
spec:
  version: v2.0
  tracing:
    type: Jaeger
    sampling: 10000
  addons:
    jaeger:
      name: jaeger
      install:
        storage:
          type: Memory
    kiali:
      enabled: true
      name: kiali
    grafana:
      enabled: true
EOF"

p "Verify the service mesh is running"
pe "oc get smcp -n $CONTROL_PLANE_NAMESPACE"

p "Create the bookinfo namespace"
pe "oc new-project $BOOKINFO_NAMESPACE"

p "Create the Service Mesh Member Roll"
pe "oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: ${CONTROL_PLANE_NAMESPACE}
spec:
  members:
    # a list of projects joined into the service mesh
    - ${BOOKINFO_NAMESPACE}
EOF"

p "Create a service mesh user for the bookinfo namespace"
pe "oc create user $BOOKINFO_MESH_USER"

p "Create a service mesh roll binding between the servic mesh users and the control plane"
pe "oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ${CONTROL_PLANE_NAMESPACE}
  name: mesh-users
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: mesh-user
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${BOOKINFO_MESH_USER}
EOF"

p "Deploy the bookinfo appliacation"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=reviews"            # reviews Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=reviews"            # reviews ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v1"     # reviews-v1 Deployment
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=ratings"            # ratings Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=ratings"            # ratings ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=ratings,version=v1"     # ratings-v1 Deployment
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=details"            # details Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=details"            # details ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=details,version=v1"     # details-v1 Deployment
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=productpage"        # productpage Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=productpage"        # productpage ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=productpage,version=v1" # productpage-v1 Deployment

p "Deploy the service mesh gateway"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $GATEWAY_CONFIG"

p "Deploy the service mesh destination rules"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_DEST_RULES"

pe "export GATEWAY_URL=$(oc -n $CONTROL_PLANE_NAMESPACE get route istio-ingressgateway -o jsonpath='{.spec.host}')"
p "GATEWAY_URL: $GATEWAY_URL"
pe "oc get route -n $CONTROL_PLANE_NAMESPACE"       #-- there should be jeager, kiali, prometheous
pe "oc get virtualservices -n $BOOKINFO_NAMESPACE"  #-- there should be virtual services: bookinfo
pe "oc get destinationrules -n $BOOKINFO_NAMESPACE" #-- there should be destination rules: details, ratings, and revies
pe "oc get gateway -n $BOOKINFO_NAMESPACE"          #-- there should be a gateway: bookinfo-gateway
pe "oc get pods -n $BOOKINFO_NAMESPACE"             #-- there should be Bookinfo pods


