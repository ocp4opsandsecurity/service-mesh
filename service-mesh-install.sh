pe "export CONTROL_PLANE_NAMESPACE=istio-system"
pe "export BOOKINFO_NAMESPACE=bookinfo"
pe "export BOOKINFO_MESH_USER=bookinfo-mesh-user"
pe "export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml"
pe "export BOOKINFO_DEST_RULES_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml"
pe "export BOOKINFO_GATEWAY_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml"


p "Installing the Red Hat Elasticsearch Operator"
pe "oc apply -n openshift-operators -f- <<EOF
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
pe ""
clear

p "Installing the Red Hat Jaeger Operator"
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
pe ""
clear

p "Installing the Red Hat Kiali Operator"
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
pe ""
clear

p "Installing the Red Hat Service Mesh Operator"
pe "oc apply -n openshift-operators -f- <<EOF
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
pe ""
clear

p "Create Control Plane Project"
pe "oc new-project $CONTROL_PLANE_NAMESPACE"
pe ""
clear

p "Create a Service Mesh Control Plane"
pe "oc apply -f- <<EOF
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
pe ""
clear

p "Control Plane Installation Status"
pe "oc get smcp -n $CONTROL_PLANE_NAMESPACE"
pe ""
clear

p "Create a project for each Service Mesh Member"
pe "oc new-project $BOOKINFO_NAMESPACE"
pe ""
clear

p "Create a ServiceMeshMemberRoll resource"
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
pe ""
clear

p "Create service mesh user"
pe "oc create user $BOOKINFO_MESH_USER"
pe ""
clear

p "Create mesh-user role binding"
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
pe ""
clear

p "Details Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=details"        # details Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=details"        # details ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=details,version=v1" # details-v1 Deployment
pe ""
clear

p "Ratings Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=ratings"        # ratings Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=ratings"        # ratings ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=ratings,version=v1" # ratings-v1 Deployment
pe ""
clear

p "Reviews Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=reviews"        # reviews Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=reviews"        # reviews ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v1" # reviews-v1 Deployment
pe ""
clear

p "Product Page Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=productpage"        # productpage Service
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=productpage"        # productpage ServiceAccount
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=productpage,version=v1" # productpage-v1 Deployment
p ""
clear

p "Create bookinfo Gateway deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_GATEWAY_YAML"
pe ""
clear

p "Add Destination Rules"
pe "oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_DEST_RULES_YAML"
pe ""
clear

p "List Pods"
pe "oc get pods -n $BOOKINFO_NAMESPACE"
pe ""
clear

p "List tool routes"
pe "oc get route -n $CONTROL_PLANE_NAMESPACE"
pe ""
clear

p "Verify Deployment"
pe "oc get virtualservices"   #-- there should be virtual services: bookinfo
pe "oc get destinationrules"  #-- there should be destination rules: details, ratings, and revies
pe "oc get gateway"           #-- there should be a gateway: bookinfo-gateway
pe "oc get pods"              #-- there should be bookinfo pods

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
