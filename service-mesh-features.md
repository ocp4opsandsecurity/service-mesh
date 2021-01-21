# service-mesh-features
How to that explores many of the powerful Service Mesh features covered in the Istio BookInfo reference applicaiton.

- [Assumptions](#assumptions)
- [Traffic Management](#traffic-management)
  - [Request Routing](#request-routing)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)

## Dependencies
1. Red Hat OpenShift Service Mesh is installed using the [Quick-Start](#quick-start)

## Traffic Management
Traffic routing lets you control the flow of traffic between services.

### Request Routing
Request routing by defaults routes traffic to all available service versions in a round-robin fashion. To demonstrate, deploy
both the `reiews v2` and `reviews v3` along side `review v1` of the reviews service. Observe the traffic dynamically 
switch between service versions by refreshing the product page in your browser.

1. Display the current routes using the following command:
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
