##########################
# include dependencies
##########################
. ./service-mesh-export.sh

p "Create Control Plane project"
pe "oc new-project ${CONTROL_PLANE_PROJECT_NAME}"
pe ""
clear

p "Create a project for each Service Mesh Member"
pe "oc new-project ${BOOKINFO_PROJECT_NAME}"
pe ""
clear

p "Create service mesh user"
pe "oc create user ${BOOKINFO_SERVICE_MESH_USER_NAM}"
pe ""
clear

p "Installing the Red Hat Operators"
pe "oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
########################################################################################################################
# Red Hat Elasticsearch, based on the open source Elasticsearch project.
########################################################################################################################
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${ELASTIC_SEARCH_SUBSCRIPTION_NAME}
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: elasticsearch-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
########################################################################################################################
# Red Hat Jaeger Operator, based on the open source Jaeger project, lets you perform tracing to monitor and
# troubleshoot transactions.
########################################################################################################################
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${JAEGER_SUBSCRIPTION_NAME}
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
########################################################################################################################
# Red Hat Kiali Operator - based on the open source Kiali project, provides observability for your service mesh. By
# using Kiali you can view configurations, monitor traffic, and view and analyze traces in a single console.
########################################################################################################################
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${KIALI_SUBSCRIPTION_NAME}
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kiali-ossm
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
########################################################################################################################
# Red Hat Service Mesh, based on the Maistra/istio project provide a platform to network and secure applications.
########################################################################################################################
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${SERVICE_MESH_SUBSCRIPTION_NAME}
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF"
pe ""
clear

p "Create Control Plane Project"
pe "oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
########################################################################################################################
# Create a ServiceMeshControlPlane resource
########################################################################################################################
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: ${SERVICE_MESH_CONTROL_PLANE_NAME}
spec:
  version: v2.0
  security:
    controlPlane:
      mtls: true
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
---
########################################################################################################################
# Create a ServiceMeshMember resource
########################################################################################################################
apiVersion: maistra.io/v1
kind: ServiceMeshMember
metadata:
  name: ${SERVICE_MESH_MEMBER_NAME}
spec:
  controlPlaneRef:
    namespace: ${CONTROL_PLANE_PROJECT_NAME}
    name: ${BOOKINFO_SERVICE_MESH_USER_NAME}
---
########################################################################################################################
# Create a ServiceMeshMemberRoll resource
########################################################################################################################
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: ${SERVICE_MESH_MEMBER_ROLL_NAME}
spec:
  members:
    # a list of projects joined into the service mesh
    - ${BOOKINFO_PROJECT_NAME}
---
########################################################################################################################
# Create the RoleBinding for the service mesh user
########################################################################################################################
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  PROJECT: ${CONTROL_PLANE_PROJECT_NAME}
  name: ${SERVICE_MESH_ROLE_BINDING_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${SERVICE_MESH_USER_ROLE_NAME}
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${BOOKINFO_SERVICE_MESH_USER_NAME}
---
EOF"
pe ""
clear

p "DestinationRules Deployment"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_DEST_RULES_ALL_URL}"
pe ""
clear

p "Virtual Services"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_VIRTUAL_SERVICE_V1_URL}"
pe ""
clear

p "Create Services, ServiceAccounts, and Deployments for V1"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l service=reviews"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l account=reviews"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l app=reviews,version=v1"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l service=details"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l account=details"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l app=details,version=v1"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l service=productpage"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l account=productpage"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l app=productpage,version=v1"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l service=ratings"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l account=ratings"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_APP_URL} -l app=ratings,version=v1"
pe ""
clear

p "Deploy Gateway"
pe "oc apply -n ${BOOKINFO_PROJECT_NAME} -f ${BOOKINFO_GATEWAY_URL}"
pe ""
clear

p "List Pods"
pe "oc get pods -n ${BOOKINFO_PROJECT_NAME}"
pe ""
clear

p "List control plane routes"
pe "oc get route -n ${CONTROL_PLANE_PROJECT_NAME}"
pe ""
clear

p "List control plane installation status"
pe "oc get smcp -n ${CONTROL_PLANE_PROJECT_NAME}"
pe ""
clear

p "List Gateway url"
pe "export GATEWAY_URL=$(oc -n ${CONTROL_PLANE_PROJECT_NAME} get route istio-ingressgateway -o jsonpath='{.spec.host}')"
pe ""
clear

p "List Product Page URL"
pe "echo http://${GATEWAY_URL}/productpage"
pe ""
clear

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
