#!/bin/bash
set -euo pipefail

## installing using helm
##

##creating namespace
if ! kubectl get namespace $CONJUR_NAMESPACE > /dev/null
then
    kubectl create namespace "$CONJUR_NAMESPACE"

fi

##initializing helm (see https://github.com/helm/helm/issues/6374)
helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm init --client-only
helm repo add cyberark https://cyberark.github.io/helm-charts
helm repo update

sleep 5

helm install cyberark/conjur-oss \
    --set ssl.hostname=$CONJUR_HOSTNAME_SSL,dataKey="$(docker run --rm cyberark/conjur data-key generate)",authenticators="authn-k8s/dev\,authn" \
    --namespace "$CONJUR_NAMESPACE" \
    --name "$CONJUR_APP_NAME"

echo "Wait for 5 seconds"
sleep 5s

kubectl get svc  conjur-oss-ingress -n $CONJUR_NAMESPACE
