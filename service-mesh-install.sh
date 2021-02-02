##########################
# include dependencies
##########################
pe "sh service-mesh-export.sh"

p "Installing the Red Hat Operators"
pe "oc apply -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elasticsearch-operator
  namespace: openshift-operators-redhat
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: elasticsearch-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
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
---
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
EOF"
pe ""
clear

p "Create Control Plane project"
pe "oc new-project istio-system"
pe ""
clear

p "Create a project for each Service Mesh Member"
pe "oc new-project bookinfo"
pe ""
clear

p "Create Control Plane Project"
pe "oc apply -f- <<EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: istio-system
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
      name: grafana
    prometheus:
      enabled: true
---
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
    # a list of projects joined into the service mesh
    - bookinfo
---
EOF"
pe ""
clear

p "List control plane installation status"
pe "oc get smcp -n istio-system -w"
pe ""
clear

p "DestinationRules Deployment"
pe "oc apply -n bookinfo -f ${BOOKINFO_DEST_RULES_ALL_URL}"
pe ""
clear

p "Virtual Services"
pe "oc apply -n bookinfo -f ${BOOKINFO_VIRTUAL_SERVICE_V1_URL}"
pe ""
clear

p "Create Services, ServiceAccounts, and Deployments"
pe "oc apply -n bookinfo -f ${BOOKINFO_APP_URL}"
pe ""
clear

p "Deploy Gateway"
pe "oc apply -n bookinfo -f ${BOOKINFO_GATEWAY_URL}"
pe ""
clear

p "List Pods"
pe "oc get pods -n bookinfo"
pe ""
clear

p "List control plane routes"
pe "oc get route -n istio-system"
pe ""
clear

p "List Gateway url"
pe "export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')"
pe ""
clear

p "List Product Page URL"
pe "echo http://${GATEWAY_URL}/productpage"
pe ""
clear

p "Send some traffic"
pe "for i in {1..10}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done"
pe ""
clear

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
