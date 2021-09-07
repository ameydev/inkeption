# Inkeption (Earlier named "K8sInPod")

`Inkeption` means having a Kubernetes cluster([kind](https://kind.sigs.k8s.io/) cluster) in a pod in a Kubernetes cluster (`KiPiK`). This sounds similar to the Docker in Docker(`DinD`) concept, where the docker commands are executed within a running Docker container. In fact `inkeption` is based on the concept of `DinD`. 

This repo has the necessary contents for doing the complete setup from creating the custom `DinD` image to the deployment specification for the pod in Kubernetes.

**Alert: This is an experimental POC and it is not recommended to be setup in production unless you are aware of what exactly it is doing. :)**

## Architecture

![Architecture](media/inkeption.png?raw=true "inkeption")

There are some points to be taken under consideration:
1. As said earlier, using `DinD`, we can execute the docker commands in a container. So `DinD` container is run on a worker node in the inkeption pod.
2. Now the `kind` cli creates a Kubernetes cluster using docker containers used as the Kubernetes nodes.
3. So in order to let `kind` create the docker containers, all we need is a docker host and an environment where the `kind` cli can be executed. And this environment is provisioned using `inkeption-image`.


Considering all the above three points one can connect the dots and figure out that we would want a docker container running in a pod (let's name it "host-pod" ) and having Docker, kind and kubectl (or any Kubernetes client application) installled in it.
This sounds quite simple but actually when tried setting it up, I encountered some problems which I will share it in this file.


## Demo:
Create the `inkeption` pod in a Kubernetes cluster by running the command.

`$ kubectl apply -f pod.yaml`

The output should look like this.
![inkeption-demo](media/inkeption-demo.png?raw=true "inkeption-demo")

## Usecases:

- Currently one usecase I can think of is that it could be used in the containerized CI-CD pipelines (eg. ArgoCD) to perform end-to-end testing of Kubernetes workloads. Using this approach one can provision the K8s clusters on the fly in the pod itself where your CI-CD workflows are getting executed. The `kind` cluster is cheap and can be spun up way faster than managed service clusters.

  I encountered a similar use-case in the past, where we needed to automate unit tests execution in an Argo Workflow. Those unit tests included the testing deployment of a Kubernetes workloads (by different ways `kubectl`, `helm-2`, `helm-3`, etc) followed by API testing of the workloads. Those workloads were designed to change the cluster functionality in terms of security and that is why they were supposed to be executed in an isolated cluster. So using this approach we could provision different K8s clusters dynamically within the same Argo workflow pod, to avoid impact of the workload on the outer cluster functioning.

If you think that the `KiPiK` can be used in any other usecases as well, then please feel free to add an issue on the repo or raise a PR with changes in the README.md file.

## Key Components:

1. `Dockerfile`: I wanted to have my own custom `DinD` image, so I created one from the base image of `ubuntu`. Having the ubuntu base image helped me in debugging the initial issues and yes the `kind` binary installation was also comparatively easier on ubuntu. 
The rest of the steps include installation of `docker-cli` (`docker-engine` does not need to be installed as the this container will be using the Docker host of underlying K8s node where "pod-a" will run.), `kubectl` installation and some more necessary packages.
The ENTRYPOINT of the docker image is a bash script (`kind/create-kind.sh`).

2. `kind/create-kind.sh`: This bash script is self explanatory. First it will create a `kind` cluster by running the command `kind create cluster --name <name>`. 
Once the kind cluster is created the kubeconfig file is automatically generated with cluster access. One thing I have observed was the apiServerAddress in kube-config file has the IP address of the "127.0.0.1". 
This is because the kind cluster has the default value of `apiServerAddress` set to `127.0.0.1`. Check details of [kind-networking](https://kind.sigs.k8s.io/docs/user/configuration/#networking). But the problem here is, the kubectl cli can not communicate with the
APIServer. It throws the below error 
`The connection to the server 127.0.0.1:44333 was refused - did you specify the right host or port?` (it can be seen in demo image as well.)
To resolve this issue, I found a workaround as to update the KUBEAPISERVER with the IP address of the kind cluster's control-plane container IP. 
The host "host-pod" container shares the docker network of name "kind" with the kind-cluster node containers, the command `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CLUSER_NAME-control-plane` will return the value of IP address from the `kind` network.
The default port of the control-plane is `6443` which is appended to the KUBEAPISERVER. The below command will update the KUBEAPISERVER in the kube-config.

    `$ kubectl config set clusters.kind-$CLUSER_NAME.server $KUBEAPISERVER`

    After setting up the $KUBEAPISERVER, now the `kubectl` commands should work fine.

3. pod.yaml: The pod spec needs some properties to be set in order to let "host-pod" use the docker daemon of the host-node. This is where exactly the security of the cluster get compromised. This is very well explained in the article [Running KIND Inside A Kubernetes Cluster For Continuous Integration
](https://d2iq.com/blog/running-kind-inside-a-kubernetes-cluster-for-continuous-integration). 
I have reffered this article to create the `pod.yaml` and so I won't be explaining it here. And I highly recommend to go through it if one wants to use `KiPiK` in their projects.

4. Makefile: Run `make inkeption-image` to create the docker image for the host-pod. The name of the image can be updated to create and push your own custom image.

## Notes:
- I have tested deploying the pod on an EKS cluster. But the same deployment did not work on the `kind` cluster running locally on my laptop.
- The base image used for `inkeption` is `ubuntu` which can be replaced with an alpine image, but to install the `kind` cli in the alpine linux would be challenging. We might need to build the kind binary runtime in the docker image itself. 
Try it out and feel free to add an issue or raise a PR with a better solution for image optimization.
- One more useful link to read more about "run kind in a kubernetes pod", [here](https://github.com/kubernetes-sigs/kind/issues/303).
