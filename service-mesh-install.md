# service-mesh-install
How to install Red Hat OpenShift Service Mesh based on Istio version 1.6.14 on Red Hat OpenShift version 4.6. To 
install the Red Hat OpenShift Service Mesh Operator, you must first install the Elasticsearch, Jaeger, and Kaili 
Operators in the service mesh control plane PROJECT. For this exercise we will also be deploying the upstream bookinfo 
reference application to allow us to test drive our deployment. 

> Use the [Walk-Through](#walk-through) if you want to automate the entering of the commands.

> Use the [Quick-Start](#quick-start) if you just want to stand everything up automatically.

## Table Of Contents
- [Assumptions](#assumptions)
- [Environment Variables](#environment-variables)
- [Red Hat Operators](#red-hat-operators)
- [Control Plane Deployment](#control-plane-deployment)
- [Service Mesh Member Deployment](#service-mesh-member-deployment)
- [Application Deployment](#application-deployment)
- [Verify Deployment](#verify-deployment)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)
- [Cleanup](#cleanup)
- [References](#references)

## Assumptions
1. Access to the `oc command`
2. Access to a user with cluster-admin permissions
3. Access to an installed OpenShift Container Platform 4.6 deployment
4. Access to an active OpenShift Container Platform 4.6 subscription
5. Enable auto-completion using the following command 
```bash
source <(oc completion bash)
``` 

## Environment Variables
To configure the environment we need to set variables for our projects and service mesh. 

1. Set the environment variables using the following command:
```bash
export MAISTRA_BRANCH=maistra-2.0
export BOOKINFO_APP_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES_ALL_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
export BOOKINFO_GATEWAY_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/bookinfo-gateway.yaml
export BOOKINFO_VIRTUAL_SERVICE_V1_URL=https://github.com/maistra/istio/raw/${MAISTRA_BRANCH}/samples/bookinfo/networking/virtual-service-all-v1.yaml
```

## Red Hat Operators
1. Install the operators needed to deploy the service mesh using the following command:
```bash
oc apply -f- <<EOF
########################################################################################################################
# Red Hat Elasticsearch, based on the open source Elasticsearch project.
########################################################################################################################
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elasticsearch-operator
  namespace: openshift-operators-redhat
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
  name: jaeger-product
  namespace: openshift-operators
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
  name: kiali-ossm
  namespace: openshift-operators
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
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
EOF
```

## Create Projects
1. Create a project for the `Control Plane` using the following commands:
```bash
oc new-project istio-system
```

2. Create a project for the applications using the following commands:
```bash
oc new-project bookinfo
```

## Control Plane Deployment
We need configure our control plane which will act as the central controller for the service mesh.

1. Create `ServiceMeshControlPlane`, `ServiceMeshMember`, `ServiceMeshMemberRoll`, and `RoleBindings` resources 
   using the following command:
```bash
oc apply -f- <<EOF
########################################################################################################################
# Create a ServiceMeshControlPlane resource
########################################################################################################################
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: istio-system
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
    prometheus:
      enabled: true
  security:
    controlPlane:
      mtls: true
    dataPlane:
      mtls: true            
---
########################################################################################################################
# Create a ServiceMeshMemberRoll resource
########################################################################################################################
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
    - bookinfo
---
EOF
```

2. Get the control plane installation status using the following command:
```bash
oc get smcp -n istio-system
```

## Application Deployment
We are going to deploy the bookinfo application.

> **!!! Caution !!!** 
> [Set Default Routes For Services](https://istio.io/latest/docs/ops/best-practices/traffic-management/#set-default-routes-for-services)
> **!!! Caution !!!**

1. Destination rules configure what happens to traffic for that destination after virtual service routing
   rules are evaluated. Apply `DestinationRule` to expose v1 destinations using the following command:
```bash
oc apply -n bookinfo -f ${BOOKINFO_DEST_RULES_ALL_URL}
```

2. Think of virtual services as how traffic is routed to a given destination. Each virtual service consists of a set 
   of routing rules that are evaluated in order. So to route all traffic to subset, `v1`, only use the following command:
```bash
oc apply -n bookinfo -f ${BOOKINFO_VIRTUAL_SERVICE_V1_URL}
```

3. Deploy the service using the following commands:
```bash
oc apply -n bookinfo -f ${BOOKINFO_APP_URL}
```

4. Deploy the `Gateway` configuration using the following command:
```bash
oc apply -n bookinfo -f ${BOOKINFO_GATEWAY_URL}
```

## Verify Deployment

1. List the running `Pods` using the following command:
```bash
oc get pods -n bookinfo
```

2. List the `Tools` routes using the following command:
```bash
oc get route -n istio-system
```

3. Export the `Gateway` URL using the following command:
```bash
export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
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

6. Send some traffic using the following commad:
```bash
for i in {1..20}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done
```

## Walk-Through
**Note** the walk through requires `Curl` and `Pipe Viewer` to be installed on your system.

1. Download walk-through scripts using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-export.sh \
     --output service-mesh-export.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-install.sh \
     --output service-mesh-install.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-install-walk-through.sh \
     --output service-mesh-install-walk-through.sh
```

2. Execute the walk-through using the following command:
```bash
sh ./service-mesh-install-walk-through.sh
```

## Quick-Start
Use this `quick-start` to install, deploy, and configure this how-to for Red Hat OpenShift Service Mesh so that your can
explore the tools and get right to it.

**Note** `Curl` and `Pipe Viewer` are to be installed on your system.

1. Download walk-through scripts using the following commands:
```bash
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh/main/demo-magic.sh \
     --output demo-magic.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-export.sh \
     --output service-mesh-export.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-install.sh \
     --output service-mesh-install.sh
curl https://raw.githubusercontent.com/ocp4opsandsecurity/service-mesh-install/main/service-mesh-quick-start.sh \
     --output service-mesh-quick-start.sh
```

2. Execute the quick-start using the following command:
```bash
sh ./service-mesh-quick-start.sh
```

## Cleanup
When you are finished you can remove the resources that we installed. 
> CAUTION: Removing any shared ElasticSearch, Kiali, Jeager, or Service Mesh subscriptions!

1. Remove `Bookinfo` project using the following command:
```bash
oc delete project bookinfo
```   

2. Delete the `Control Plane Project` using the following command:
```bash
oc delete project istio-system
```

3. Unset environment variables using the following command:
```bash
unset MAISTRA_BRANCH
unset BOOKINFO_APP_URL
unset BOOKINFO_DEST_RULES_ALL_URL
unset BOOKINFO_GATEWAY_URL
unset BOOKINFO_VIRTUAL_SERVICE_V1_URL
```

## References

### Operator API
- [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html)

### Red Hat OpenShift
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)

### Upstream Projects
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/) 

### Trouble Shooting
- [Unable To Delete PROJECT](https://access.redhat.com/solutions/4165791)

