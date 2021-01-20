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
3. Environment Variables
```bash
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_DEST_RULES=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
```

## Traffic Management
Traffic routing lets you control the flow of traffic between services.

### Request Routing
Configure dynamic request routing to multiple versions of a microservice. To demonstrate, we will deploy
both `reiews v2` and `reviews v3` along side `review v1` of the reviews service. Watch the traffic dynamically 
switch between service versions as you refresh the product page in your browser.

1. Deploy `reviews v2` service and refresh the product page until you see BLACK star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v2
```

2. Deploy `reviews v3` service and refresh the product page until you see RED star reviews:
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v3
```

## References

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

## Trouble Shooting
- [Unable To Delete Namespace](https://access.redhat.com/solutions/4165791)
