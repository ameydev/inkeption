# K8sInPod

Yes that's right, `K8sInPod` means having a cluster ([kind](https://kind.sigs.k8s.io/) cluster) running in a pod. This sounds similar to the Docker in Docker(`DinD`) concept, where the docker commands are executed within a running Docker container. In fact `K8sInPod` is based on the concept of `DinD`. 


![K8sInPod](K8sInPod.png?raw=true "K8sInPod")

This repo has the necessary contents for doing the complete setup from creating the custom DinD image to the deployment specification for the pod in Kubernetes.

**Alert: This is an experimental POC and it is not recommended to be setup in production unless you are aware of what exactly it is doing. :)**

## Architecture

There are some points to be taken under consideration:
1. As said earlier, using `DinD`, we can execute the docker commands in a container. So `DinD` container is run on a worker node in the k8s-in-pod pod.
2. Now the `kind` cli creates a Kubernetes cluster using docker containers used as the Kubernetes nodes.
3. So in order to let `kind` create the docker containers, all we need is a docker host and an environment where the `kind` cli can be executed. And this environment is provisioned using `k8s-in-pod-image`.


Considering all the above three points one can connect the dots and figure out that we would want a docker container running in a pod (let's name it "host-pod" ) and having Docker, kind and kubectl (or any Kubernetes client application) installled in it.
This sounds quite simple but actually when tried setting it up, I encountered some problems which I will share it in this file.

## Key Components:

1. `Dockerfile`: I wanted to have my own custom `DinD` image, so I created one from the base image of `ubuntu`. Having the ubuntu base image helped me in debugging the initial issues and yes the `kind` binary installation was also comparatively easier on ubuntu. 
The rest of the steps include installation of `docker-cli` (`docker-engine` does not need to be installed as the this container will be using the Docker host of underlying K8s node where "pod-a" will run.), `kubectl` installation and some more necessary packages.
The ENTRYPOINT of the docker image is a bash script (`kind/create-kind.sh`).

2. `kind/create-kind.sh`: This bash script is self explanatory. First it will create a `kind` cluster by running the command `kind create cluster --name <name>`. 
Once the kind cluster is created the kubeconfig file is automatically generated with cluster access. One thing I have observed was the apiServerAddress in kube-config file has the IP address of the "127.0.0.1". 
This is because the kind cluster has the default value of `apiServerAddress` set to `127.0.0.1`. Check details of [kind-networking](https://kind.sigs.k8s.io/docs/user/configuration/#networking). But the problem here is, the kubectl cli can not communicate with the
APIServer. It throws the below error 
```
The connection to the server 127.0.0.1:44333 was refused - did you specify the right host or port?
```
To resolve this issue, I found a workaround as to update the APIServer-Address with the IP address of the kind cluster's control-plane container IP. 
The host "host-pod" container shares the docker network of name "kind" with the kind-cluster node containers, the command `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CLUSER_NAME-control-plane` will return the value of IP address from the `kind` network.
The default port of the control-plane is `6443` which is appended to the APIServer-Address.

After setting up the apiServerAddress, now the `kubectl` commands should work fine now.

3. pod.yaml: The pod spec needs some custom properties to be set in order to let "host-pod" use the docker daemon of the host-node. Let's go through it one by one. The explaination of the pod-spec requirement is very well written in the [article](https://d2iq.com/blog/running-kind-inside-a-kubernetes-cluster-for-continuous-integration). 
I have reffered this article to create the pod-spec and so I won't be explaining it here.

4. Makefile: Run `make k8s-in-pod-image` to create the docker image for the host-pod. The name of the image can be updated.

## Notes:
- I have tested deploying the pod on an EKS cluster. But the same deployment did not work on the `kind` cluster running locally on my laptop.
- The base image used for "K8sInPod" is ubuntu which can be replaced with an alpine image, but to install the kind cli in the alpine linux would be challenging. We might need to use multi-stage docker build with one of the stage is used for building the kind binary. 
Try it out and feel free to add an issue or raise a PR with a better solution for image optimization.
- One more useful link to read more about "run kind in a kubernetes pod", [here](https://github.com/kubernetes-sigs/kind/issues/303).
