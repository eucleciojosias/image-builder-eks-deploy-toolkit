FROM ubuntu:25.10

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -qq -y \
    curl python3 python3-pip \
    apt-transport-https ca-certificates \
    unzip groff less jq git yq gpg

RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

RUN apt update

RUN apt install -y kubectl helm

RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip -qq awscliv2.zip
RUN ./aws/install
RUN rm -rf awscliv2.zip

RUN aws --version
RUN kubectl version --client
RUN helm version

#############

ARG HELM_REPO
ARG HELM_REPO_URL

ENV HELM_REPO=$HELM_REPO
ENV HELM_REPO_URL=$HELM_REPO_URL

WORKDIR /
COPY ./scripts/*.sh /
