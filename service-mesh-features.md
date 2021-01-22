# service-mesh-features
How to that explores many of the powerful Service Mesh features covered in the Istio BookInfo reference application.

> Use the [Walk-Through](#walk-through) if you want to automate the entering of the commands.

> Use the [Quick-Start](#quick-start) if you just want to stand everything up automatically.

- [Assumptions](#assumptions)
- [Traffic Management](#traffic-management)
  - [Request Routing](#request-routing)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)

## Assumptions
- Red Hat OpenShift Service Mesh is installed and configured using the [Quick-Start](#quick-start) or the procedure as 
described in the [Service Mesh Install](service-mesh-install.md) how-to.

## Traffic Management
Traffic routing lets you control the flow of traffic between services.

### Request Routing
Request routing by defaults routes traffic to all available service versions in a round-robin fashion. To demonstrate, deploy
both the `reiews v2` and `reviews v3` along side `review v1` of the reviews service. Observe the traffic dynamically 
switch between service versions by refreshing the product page in your browser.

1. Display the current routes using the following command:
```bash
oc get virtualservices -n $BOOKINFO_NAMESPACE  #-- there should be virtual services: bookinfo
oc get destinationrules -n $BOOKINFO_NAMESPACE #-- there should be destination rules: details, ratings, and revies
oc get gateway -n $BOOKINFO_NAMESPACE          #-- there should be a gateway: bookinfo-gateway
oc get pods -n $BOOKINFO_NAMESPACE             #-- there should be bookinfo pods
```

#### Virtual Services and Destination Rules
Think of virtual services as how you route your traffic to a given destination, and then you use destination rules to 
configure what happens to traffic for that destination. Destination rules are applied after virtual service routing 
rules are evaluated, so they apply to the traffic’s “real” destination.

1. Apply `Destination Rules` using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_DEST_RULES_YAML
```

2. Deploy `reviews v2` service and refresh the product page until you see BLACK star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v2
```

3. Deploy `reviews v3` service and refresh the product page until you see RED star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v3
```

#### Virtual Service
A virtual service lets you configure how requests are routed to a service within a service mesh, building on the basic
connectivity and discovery provided by the service mesh platform. Each virtual service consists of a set of routing
rules that are evaluated in order, letting the service mesh match each request to the virtual service to a specific real 
destination within the mesh.

1. Route all traffic to subset, `v1`, only use the following command:
```bash
oc apply -f- <<EOF
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

#### A/B Testing
A/B testing is a method of comparing two versions.

1. Route 100% of review traffic to version `v2` using the following command:
```bash
oc apply -f- <<EOF
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
EOF
```

#### Load Balancing
Round-robin is the default load balancing policy, where each service instance in the instance pool gets a request in turn.

Supported load balancing policy models:
- **Random:** Requests are forwarded at random to instances in the pool.
- **Weighted:** Requests are forwarded in the pool according to a specific percentage.
- **Least requests:** Requests are forwarded to the instances with the least number of requests.


1. **Weighted** example routes the bulk of the review traffic to version `v2` with the balance routed to `v3` using the following command:
```bash
oc apply -f- <<EOF
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
EOF
```

2. **Random** example distributes the review traffic to version `v1`, `v2`, `v3` using the following command:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
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
EOF
```

## Walk-Through
Use this walk-through as an automated guide explore Red Hat Service Mesh features based on the Istio BookInfo reference 
application. 

> **Note** `Curl` and `Pipe Viewer` are to be installed on your system.

1. Download demo-magic script using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
```

2. Download the walk-through script using the following command:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/service-mesh-features-walk-through.sh \
     --output service-mesh-features-walk-through.sh
```

3. Execute the walk-through using the following command:
```bash
sh ./service-mesh-features-walk-through.sh
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

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

## Trouble Shooting
- [Unable To Delete Namespace](https://access.redhat.com/solutions/4165791)
