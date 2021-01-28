# service-mesh-install
How to install Red Hat OpenShift Service Mesh based on Istio version 1.6.14 on Red Hat OpenShift version 4.6. To 
install the Red Hat OpenShift Service Mesh Operator, you must first install the Elasticsearch, Jaeger, and Kaili 
Operators in the service mesh control plane PROJECT. For this exercise we will also be deploying the upstream bookinfo 
reference application to allow us to test drive our deployment. 

> Use the [Walk-Through](#walk-through) if you want to automate the entering of the commands.

> Use the [Quick-Start](#quick-start) if you just want to stand everything up automatically.

## Table Of Contents
- [Operator Installation](#operator-installation)
- [Control Plane Deployment](#control-plane-deployment)
- [Service Member Deployment](#service-member-deployment)
- [Application Deployment](#applicaiton-deployment)
- [Tools](#tools)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)
- [Cleanup](#cleanup)
- [References](#references)

## Operator Installation
To install the operators, you must log in to the OpenShift Container Platform as a user with the cluster-admin role.

### Assumptions
1. Access to the `oc command`
2. Access to a user with cluster-admin permissions
3. Access to an installed OpenShift Container Platform 4.6 deployment
4. Access to an active OpenShift Container Platform 4.6 subscription
5. Enable auto-completion using the following command 
```bash
source <(oc completion bash)
``` 

## Export Environment Variables
To configure the environment we need to set variables for our projects and service mesh. 

1. Set the environment variables using the following command:
```bash
export OPERATORS_PROJECT_NAME=openshift-operators
export CONTROL_PLANE_PROJECT_NAME=istio-system-project
export BOOKINFO_PROJECT_NAME=bookinfo-project
export BOOKINFO_SERVICE_MESH_USER_NAME=user-bookinfo-service-mesh
export BOOKINFO_GATEWAY_NAME=bookinfo-gateway
export SERVICE_MESH_CONTROL_PLANE_NAME=${CONTROL_PLANE_PROJECT_NAME}-control-plane
export SERVICE_MESH_ROLE_BINDING_NAME=service-mesh-users
export SERVICE_MESH_MEMBER_NAME=default
export SERVICE_MESH_SUBSCRIPTION_NAME=servicemeshoperator
export SERVICE_MESH_USER_ROLE_NAME=service-mesh-user
export SERVICE_MESH_MEMBER_ROLL_NAME=default
export KIALI_SUBSCRIPTION_NAME=kiali-ossm
export JAEGER_SUBSCRIPTION_NAME=jaeger-product-subscription
export ELASTIC_SEARCH_SUBSCRIPTION_NAME=elasticsearch-subscription
export BOOKINFO_APP_YAML_URL=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES_YAML_URL=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export BOOKINFO_GATEWAY_YAML_URL=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
export BOOKINFO_VIRTUAL_SERVICE_NAME=bookinfo
```

### Installing the Red Hat Elasticsearch Operator
Elasticsearch, based on the open source Elasticsearch project.

1. Create a Subscription object using the following command:
```bash
oc apply -n ${OPERATORS_PROJECT_NAME} -f- <<EOF
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
EOF
```

### Install the Red Hat Jaeger Operator
Jaeger, based on the open source Jaeger project, lets you perform tracing to monitor and troubleshoot transactions.
 
1. Create a Subscription object using the following command:
```bash
oc apply -n ${OPERATORS_PROJECT_NAME} -f- <<EOF
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
EOF
```

### Install the Red Hat Kiali Operator
Kiali - based on the open source Kiali project, provides observability for your service mesh. By using Kiali you can 
view configurations, monitor traffic, and view and analyze traces in a single console.

1. Create a Subscription object using the following command:
```bash
oc apply -n ${OPERATORS_PROJECT_NAME} -f- <<EOF
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
EOF
```

### Install the Red Hat Service Mesh Operator
Red Hat Service Mesh, based on the Maistra/istio project provide a platform to network and secure applications.

1. Create a new subscription that deploys the service mesh operator.
```bash
oc apply -n ${OPERATORS_PROJECT_NAME} -f- <<EOF
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
EOF
```

## Control Plane Deployment 
We need a project to deploy and configure our control plane which will act as the central controller for the service mesh.

1. Create a project for the `Control Plane` using the following commands:
```bash
oc new-project ${CONTROL_PLANE_PROJECT_NAME}
```

2. Create a ServiceMeshControlPlane object using the following command:
```bash
oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: ${SERVICE_MESH_CONTROL_PLANE_NAME}
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
EOF
```

3. Get the control plane installation status using the following command:
```bash
oc get smcp -n ${CONTROL_PLANE_PROJECT_NAME}
```

### Create Service Mesh Member User
Create a user to access resources that does not have privileges to add members to the ServiceMeshMemberRoll directly.

1. Create a `user` for each project in the service mesh using the following commands:
```bash
oc create user ${BOOKINFO_SERVICE_MESH_USER_NAME}
```

2. Create a service mesh member binding between the 
```bash
oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMember
metadata:
  name: ${SERVICE_MESH_MEMBER_NAME}
spec:
  controlPlaneRef:
    namespace: ${CONTROL_PLANE_PROJECT_NAME}
    name: ${BOOKINFO_SERVICE_MESH_USER_NAME}
EOF
```

3. Create a `ServiceMeshMemberRoll` resource using the following command:
```bash
oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: ${SERVICE_MESH_MEMBER_ROLL_NAME}
spec:
  members:
    # a list of projects joined into the service mesh
    - ${BOOKINFO_PROJECT_NAME}
EOF
```
  
4. Create the `RoleBinding` for the service mesh user using the following command:
```bash
oc apply -n ${CONTROL_PLANE_PROJECT_NAME} -f- <<EOF
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
EOF
```

### Create the Bookinfo application

1. Create a project for the applications using the following commands:
```bash
oc new-project ${BOOKINFO_PROJECT_NAME}
```

2. Deploy `v1` Service, ServiceAccount,  using the following commands
```bash
oc apply -n ${BOOKINFO_PROJECT_NAME} -f- <<EOF
##################################################################################################
# Details service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
    service: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-details
  labels:
    account: details
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: details-v1
  labels:
    app: details
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: details
      version: v1
  template:
    metadata:
      labels:
        app: details
        version: v1
    spec:
      serviceAccountName: bookinfo-details
      containers:
      - name: details
        image: maistra/examples-bookinfo-details-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
##################################################################################################
# Ratings service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
    service: ratings
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: ratings
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-ratings
  labels:
    account: ratings
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ratings-v1
  labels:
    app: ratings
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ratings
      version: v1
  template:
    metadata:
      labels:
        app: ratings
        version: v1
    spec:
      serviceAccountName: bookinfo-ratings
      containers:
      - name: ratings
        image: maistra/examples-bookinfo-ratings-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
##################################################################################################
# Reviews service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
    service: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-reviews
  labels:
    account: reviews
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v1
  labels:
    app: reviews
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reviews
      version: v1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      serviceAccountName: bookinfo-reviews
      containers:
      - name: reviews
        image: maistra/examples-bookinfo-reviews-v1:2.0.0
        imagePullPolicy: IfNotPresent
        env:
        - name: LOG_DIR
          value: "/tmp/logs"
        ports:
        - containerPort: 9080
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: wlp-output
          mountPath: /opt/ibm/wlp/output
      volumes:
      - name: wlp-output
        emptyDir: {}
      - name: tmp
        emptyDir: {}
---
##################################################################################################
# Productpage services
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
    service: productpage
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-productpage
  labels:
    account: productpage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productpage-v1
  labels:
    app: productpage
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: productpage
      version: v1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      serviceAccountName: bookinfo-productpage
      containers:
      - name: productpage
        image: maistra/examples-bookinfo-productpage-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
---
EOF
```

3. Think of virtual services as how traffic is routed to a given destination. Each virtual service consists of a set of routing rules that are evaluated in order. So to route all traffic to subset, `v1`, only use the following command:
```bash
oc apply -n ${BOOKINFO_PROJECT_NAME} -f- <<EOF
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
EOF
```

3. Verify the `VirtualServices` using the following commands:
```bash
oc get virtualservices -n ${BOOKINFO_PROJECT_NAME}
```

4. Destination rules configure what happens to traffic for that destination after virtual service routing
   rules are evaluated. Apply `Destination Rules` to expose v1 destinations using the following command:
```bash
oc apply -n ${BOOKINFO_PROJECT_NAME} -f- <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details
spec:
  host: details
  subsets:
  - name: v1
    labels:
      version: v1
---
EOF
```

5. List the `DestinationRule` using the following command:
```bash
oc get destinationrules -n${BOOKINFO_PROJECT_NAME}
```

6. Deploy the `Gateway` configuration using the following command:
```bash
oc apply -n ${BOOKINFO_PROJECT_NAME} -f- <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ${BOOKINFO_GATEWAY_NAME}
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ${BOOKINFO_VIRTUAL_SERVICE_NAME}
spec:
  hosts:
  - "*"
  gateways:
  - ${BOOKINFO_GATEWAY_NAME}
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
---
EOF
```

### Verify Deployment

1. List the running `Pods` using the following command:
```bash
oc get pods -n ${BOOKINFO_PROJECT_NAME}
```

2. List the `Tools` routes using the following command:
```bash
oc get route -n ${CONTROL_PLANE_PROJECT_NAME}
```   

3. List the `Gateway` URL using the following command:
```bash
export GATEWAY_URL=$(oc -n ${CONTROL_PLANE_PROJECT_NAME} get route istio-ingressgateway -o jsonpath='{.spec.host}')
```

4. On the http://${GATEWAY_URL}/productpage of the Bookinfo application, refresh the browser. 
```bash
echo http://${GATEWAY_URL}/productpage
```

You should see that the traffic is routed to the v1 services.

> An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!
> - Reviewer1


> Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.
> - Reviewer2

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

## Cleanup
When you are finished you can remove the resources that we installed. 
> CAUTION: Removing any shared ElasticSearch, Kiali, Jeager, or Service Mesh subscriptions!

1. Unset environment variables using the following command:
```bash
unset OPERATORS_PROJECT_NAME
unset CONTROL_PLANE_PROJECT_NAME
unset BOOKINFO_APP_YAML_URL
unset BOOKINFO_DEST_RULES_YAML_URL
unset BOOKINFO_GATEWAY_YAML_URL
unset BOOKINFO_GATEWAY_NAME
unset BOOKINFO_PROJECT_NAME
unset BOOKINFO_SERVICE_MESH_USER_NAME
unset BOOKINFO_VIRTUAL_SERVICE_NAME
unset SERVICE_MESH_CONTROL_PLANE_NAME
unset SERVICE_MESH_ROLE_BINDING_NAME
unset SERVICE_MESH_MEMBER_NAME
unset SERVICE_MESH_SUBSCRIPTION_NAME
unset SERVICE_MESH_USER_ROLE_NAME
unset SERVICE_MESH_MEMBER_ROLL_NAME
unset KIALI_SUBSCRIPTION_NAME
unset JAEGER_SUBSCRIPTION_NAME
unset ELASTIC_SEARCH_SUBSCRIPTION_NAME

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
- [Unable To Delete PROJECT](https://access.redhat.com/solutions/4165791)

