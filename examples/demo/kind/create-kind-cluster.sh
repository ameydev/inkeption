#!/bin/bash

CLUSER_NAME="test"

# Delete any previous kind custer if exists. 
kind delete clusters $CLUSER_NAME

sleep 15

kind create cluster --name $CLUSER_NAME --config config.yaml

sleep 15

# This command should fail and would throw an error, 
# The connection to the server 127.0.0.1:44333 was refused - did you specify the right host or port?
kubectl cluster-info


export API_SERVER_IP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CLUSER_NAME-control-plane`
KUBEAPISERVER="https://$API_SERVER_IP:6443"

echo $KUBEAPISERVER
# After setting up new KUBEAPISERVER, the kubectl command should run
kubectl config set clusters.kind-$CLUSER_NAME.server $KUBEAPISERVER
kubectl cluster-info

# wait for nodes to get ready.
sleep 15
# Check if kubectl can connect with API Server.
kubectl get nodes
