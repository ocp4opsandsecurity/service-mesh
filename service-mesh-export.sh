#!/bin/bash

export MAISTRA_BRANCH=maistra-2.0
export BOOKINFO_PROJECT=bookinfo
export BOOKINFO_APP_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES_ALL_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
export BOOKINFO_GATEWAY_URL=https://raw.githubusercontent.com/Maistra/istio/${MAISTRA_BRANCH}/samples/bookinfo/networking/bookinfo-gateway.yaml
export BOOKINFO_VIRTUAL_SERVICE_V1_URL=https://github.com/maistra/istio/raw/${MAISTRA_BRANCH}/samples/bookinfo/networking/virtual-service-all-v1.yaml
export CONTROL_PROJECT=istio-system
