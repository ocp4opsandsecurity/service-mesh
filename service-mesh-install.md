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
export BOOKINFO_NAMESPACE=bookinfo
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
export BOOKINFO_MESH_USER=bookinfo-mesh-user
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
1. Create bookinfo `reviews v1` deployment using the following command:
```bash
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
      annotations:
        sidecar.istio.io/inject: "true"
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
```

2. Create bookinfo `ratings v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
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
      annotations:
        sidecar.istio.io/inject: "true"
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
EOF
```

3. Create bookinfo `details v1` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
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
      annotations:
        sidecar.istio.io/inject: "true"
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
EOF
```

5. Create bookinfo `Product Page` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
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
      annotations:
        sidecar.istio.io/inject: "true"
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

6. Create bookinfo `Gateway` deployment using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
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
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
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
EOF
```

7. Export Gateway URL using the following command:
```bash
export GATEWAY_URL=$(oc -n $CONTROL_PLANE_NAMESPACE get route istio-ingressgateway -o jsonpath='{.spec.host}')
echo $GATEWAY_URL
```

8. Add `Destination Rules` for v1 services using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
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

9. List Pods using the following command:
```bash
oc get pods -n $BOOKINFO_NAMESPACE
```   

10. Verify Deployment using the following command:
```bash
curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage
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

