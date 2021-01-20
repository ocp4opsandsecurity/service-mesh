# service-mesh-features
How to that explores many of the powerful Service Mesh features.

- [Assumptions](#assumptions)
- [Traffic Management](#traffic-management)
  - [Request Routing](#request-routing)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)

## Assumptions
1. Red Hat OpenShift Service Mesh is installed using the proceedure described in [Service Mesh Install](service-mesh-install.md). See the [Service Mesh Install Quick Start](#service-mesh-install-quick-start.sh) if you want to quickly install a compliant instance of our Service Mesh how-to baseline deployment.

2. The bookinfo application topology should consist of the following resources.
```bash
oc get virtualservices   #-- there should be virtual services: bookinfo
oc get destinationrules  #-- there should be destination rules: details, ratings, and revies 
oc get gateway           #-- there should be a gateway: bookinfo-gateway
oc get pods              #-- there should be Bookinfo pods 
```
3. Export Environment Variables
```bash
export CONTROL_PLANE_NAMESPACE=istio-system
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_MESH_USER=bookinfo-mesh-user
export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export GATEWAY_CONFIG=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
```

## Traffic Management
Traffic routing lets you control the flow of traffic between services.

### Request Routing
Request routing by defaults routes traffic to all available service versions in a round robin fashion. To demonstrate, deploy
both the `reiews v2` and `reviews v3` along side `review v1` of the reviews service. Observe the traffic dynamically 
switch between service versions by refreshing the product page in your browser.

1. Display the curret routes using the following command:
```bash
oc describe virtualservices
```

2. Deploy `reviews v2` service and refresh the product page until you see BLACK star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v2
```

3. Deploy `reviews v3` service and refresh the product page until you see RED star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v3
```
.
4. To route requests to a single destination subset, `v1`, only use the following command:
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
EOF
```

## Walk-Through
Use this walk-through as an automated guide explore Red Hat Service Mesh features based on the Istio BookInfo reference application. 

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

## Install Quick-Start
Use this `quick-start` to install, deploy, and configure this how-to's flavor of a Red Hat OpenShift Service Mesh deployment.

**Note** `Curl` and `Pipe Viewer` are to be installed on your system.

1. Download demo-magic script using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
```

2. Download the quick-start script using the following command:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/service-mesh-features-quick-start.sh \
     --output service-mesh-features-quick-start.sh
```

3. Execute the quick-start using the following command:
```bash
sh ./service-mesh-features-quick-start.sh
```

## References

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

## Trouble Shooting
- [Unable To Delete Namespace](https://access.redhat.com/solutions/4165791)
