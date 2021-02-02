p "Installing the Red Hat Operators"
pe "oc apply -f ./install-subscription.yaml"
pe ""
clear

p "Create Control Plane project"
pe "oc new-project istio-system"
pe ""
clear

p "Create a project for each Service Mesh Member"
pe "oc new-project bookinfo"
pe ""
clear

p "Create Control Plane Project"
pe "oc apply -f ./install-control-plane.yaml"
pe ""
clear

p "List control plane installation status"
pe "oc get smcp -n istio-system -w"
pe ""
clear

p "DestinationRules Deployment"
pe "oc apply -n bookinfo -f ./install-destination-rule-all-mtls.yaml"
pe ""
clear

p "Virtual Services"
pe "oc apply -n bookinfo -f ./install-virtual-service-all-v1.yaml"
pe ""
clear

p "Create Services, ServiceAccounts, and Deployments"
pe "oc apply -n bookinfo -f ./install-bookinfo.yaml"
pe ""
clear

p "Deploy Gateway"
pe "oc apply -n bookinfo -f ./install-bookinfo-gateway.yaml"
pe ""
clear

p "List Pods"
pe "oc get pods -n bookinfo"
pe ""
clear

p "List control plane routes"
pe "oc get route -n istio-system"
pe ""
clear

p "List Gateway url"
pe "export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')"
pe ""
clear

p "List Product Page URL"
pe "echo http://${GATEWAY_URL}/productpage"
pe ""
clear

p "Send some traffic"
pe "for i in {1..10}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done"
pe ""
clear

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
