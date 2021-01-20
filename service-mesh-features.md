# service-mesh-features
How to that explores many of the powerful Service Mesh features

## Assumptions
1. Red Hat OpenShift Service Mesh is installed using the proceedure in [Service Mesh Install](service-mesh-install.md).

2. The bookinfo application topology should consist of the following resources.
```bash
oc get virtualservices   #-- there should be virtual services: bookinfo
oc get destinationrules  #-- there should be destination rules: details, ratings, and revies 
oc get gateway           #-- there should be a gateway: bookinfo-gateway
oc get pods              #-- there should be Bookinfo pods 
```
3. Export Environment Variables
```bash
export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export BOOKINFO_NAMESPACE=bookinfo
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

#### Virtual Serivices
To route requests to a single microservie version only, apply `virtual services` that sets the default version.

1. 
```bash
oc apply -f- <<EOF
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - details
    http:
    - route:
      - destination:
          host: details
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - productpage
    http:
    - route:
      - destination:
          host: productpage
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - ratings
    http:
    - route:
      - destination:
          host: ratings
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
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


## References

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

## Trouble Shooting
- [Unable To Delete Namespace](https://access.redhat.com/solutions/4165791)
