FROM ubuntu AS dind-ubuntu

RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    vim \
    git \
    lsb-release

# Install Docker cli
ENV DOCKERVERSION=18.03.1-ce
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz


FROM dind-ubuntu
WORKDIR /app

# install kubectl
RUN KUBE_LATEST_VERSION=`curl https://storage.googleapis.com/kubernetes-release/release/stable.txt` \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBE_LATEST_VERSION/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectl

# download kind in builder
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-$(uname)-amd64  && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/

ADD kind /app/
ENTRYPOINT ["./create-kind.sh" ]
