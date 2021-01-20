# service-mesh-features


## Traffic Management

### Request Routing
1. Deploy `reviews v2` see the BLACK Stars
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v2
```

2. Deploy `reviews v3` see the RED Stars
```bash
oc apply -n $BOOKINFO_NAMESPACE -f $BOOKINFO_APP_YAML -l app=reviews,version=v3
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
