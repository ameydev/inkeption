#!/bin/bash

CLUSER_NAME="test"

# Delete any previous kind custer if exists. 
kind delete clusters $CLUSER_NAME

sleep 15

kind create cluster --name $CLUSER_NAME --config config.yaml

sleep 15

kubectl cluster-info
API_SERVER_IP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CLUSER_NAME-control-plane`
KUBEAPISERVER="https://$API_SERVER_IP:6443"

echo $KUBEAPISERVER

kubectl config set clusters.kind-$CLUSER_NAME.server $KUBEAPISERVER
kubectl cluster-info

# Check if kubectl can connect with API Server.
kubectl get nodes

# Deploy sample workload
kubectl run hello-world --image hello-world
kubectl get pods

# Keep the container in running state
tail -f /dev/null
