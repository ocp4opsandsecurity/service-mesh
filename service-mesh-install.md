# service-mesh-install
How to install Red Hat OpenShift Service Mesh based on Istio version 1.6.14 on Red Hat OpenShift version 4.6. To 
install the Red Hat OpenShift Service Mesh Operator, you must first install the Elasticsearch, Jaeger, and Kaili 
Operators in the service mesh control plane namespace. For this exercise we will also be deploying the upstream bookinfo 
reference application to allow us to test drive our deployment. 

Use the [Walk-Through](#walk-through) if you are in a hurry.

## Table Of Contents
- [Operator Installation](#operator-installation)
- [Control Plane Deployment](#control-plane-deployment)
- [Service Member Creation](#service-member-creation)
- [Application Deployment](#applicaiton-deployment)
- [Tools](#tools)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)

## Operator Installation
To install the operators, you must log in to the OpenShift Container Platform as a user with the cluster-admin role.

### Assumptions
- Access to the `oc command`
- Access to a user with cluster-admin permissions
- Access to an installed OpenShift Container Platform 4.6 deployment
- Access to an active OpenShift Container Platform 4.6 subscription

### Auto Completion 
Ensure Make sure auto-completion for the OC command is enabled so that pod names are easy to access because pod names
have with randomly generated suffixes. 
```bash
source <(oc completion bash)
``` 

### Export Environment Variables
```bash
export CONTROL_PLANE_NAMESPACE=istio-system
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_MESH_USER=bookinfo-mesh-user
export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export BOOKMARK_GATEWAY_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
```

### Installing the Red Hat Elasticsearch Operator
Elasticsearch, based on the open source Elasticsearch project.

Create a Subscription object using the following command:
```bash
oc apply -n openshift-operators -f- <<EOF
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
EOF
```

### Install the Red Hat Jaeger Operator
Jaeger, based on the open source Jaeger project, lets you perform tracing to monitor and troubleshoot transactions.
 
Create a Subscription object using the following command:
```bash
oc apply -n openshift-operators -f- <<EOF
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
EOF
```

### Install the Red Hat Kiali Operator
Kiali - based on the open source Kiali project, provides observability for your service mesh. By using Kiali you can 
view configurations, monitor traffic, and view and analyze traces in a single console.

Create a Subscription object using the following command:
```bash
oc apply -n openshift-operators -f- <<EOF
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
EOF
```

### Install the Red Hat Service Mesh Operator
```bash
oc apply -f- <<EOF
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
EOF
```

## Control Plane Deployment 

1. Export the environment variable for the `Control Plan Deployment` namespace using the following command:
```bash
export CONTROL_PLANE_NAMESPACE=istio-system
```

2. Create a project for the `Control Plane Deployment` using the following commands:
```bash
oc new-project $CONTROL_PLANE_NAMESPACE
```

3. Create a ServiceMeshControlPlane object using the following command:
```bash
oc apply -f- <<EOF
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
EOF
```

3. Get the control plane installation status using the following command:
```bash
oc get smcp -n $CONTROL_PLANE_NAMESPACE
```

## Service Members

### Service Member Roll Creation
1. Create projects for each `Service Mesh Member` using the following commands:
```bash
oc new-project $BOOKINFO_NAMESPACE
```

2. Create a ServiceMeshMemberRoll resource using the following command:
```bash
oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: ${CONTROL_PLANE_NAMESPACE}
spec:
  members:
    # a list of projects joined into the service mesh
    - ${BOOKINFO_NAMESPACE}
EOF
```

#### Service Member Creation
1. Create a service mesh `user` for each project using the following commands:
```bash
oc create user $BOOKINFO_MESH_USER
```

2. Create the `mesh-user role binding` using the following command:
```bash
oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
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
EOF
```

## Application Deployment
1. Create bookinfo `Reviews v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=reviews        # reviews Service
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=reviews        # reviews ServiceAccount
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v1 # reviews-v1 Deployment
```

2. Create bookinfo `Details v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=details        # details Service
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=details        # details ServiceAccount
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=details,version=v1 # details-v1 Deployment
```

3. Create bookinfo `Product Page v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=productpage        # productpage Service
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=productpage        # productpage ServiceAccount
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=productpage,version=v1 # productpage-v1 Deployment
```

5. Create bookinfo `Rating v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l service=ratings        # ratings Service
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l account=ratings        # ratings ServiceAccount
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=ratings,version=v1 # ratings-v1 Deployment
```

6. Create bookinfo `Gateway` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKMARK_GATEWAY_YAML
```

7. Add `Destination Rules` using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_DEST_RULES_YAML
```

8. List Pods using the following command:
```bash
oc get pods -n $BOOKINFO_NAMESPACE
```   

## Tool Routes 

1. List the routes for each tools using the following command:
```bash
oc get route -n $CONTROL_PLANE_NAMESPACE 
```

## Walk-Through
**Note** the walk through requires `Curl` and `Pipe Viewer` to be installed on your system.

1. Download demo-magic script using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
```

2. Download walk through script using the following command:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-install.sh \
     --output service-mesh-install-walk-through.sh
```

3. Execute the walk through using the following command:
```bash
sh ./service-mesh-install-walk-through.sh
```

## Quick-Start
Use this `quick-start` to install, deploy, and configure this how-to for Red Hat OpenShift Service Mesh so that your can
explore the tools and get right to it.

**Note** `Curl` and `Pipe Viewer` are to be installed on your system.

1. Download demo-magic script using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
```

2. Download the quick-start script using the following command:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/service-mesh-features-quick-start.sh \
     --output service-mesh-quick-start.sh
```

3. Download the install script using the following command:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/service-mesh-install.sh \
     --output service-mesh-install.sh
```

4. Execute the quick-start using the following command:
```bash
sh ./service-mesh-quick-start.sh
```

## References

### Operator API
- [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html)

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

## Trouble Shooting
- [Unable To Delete Namespace](https://access.redhat.com/solutions/4165791)

