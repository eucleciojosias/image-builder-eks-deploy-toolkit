FROM ubuntu:25.10

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -qq -y \
    curl git \
    apt-transport-https ca-certificates \
    unzip gpg

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt update
RUN apt install -y docker-ce-cli

RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip -qq awscliv2.zip
RUN ./aws/install
RUN rm -rf awscliv2.zip

RUN aws --version
RUN docker --version
RUN git --version

WORKDIR /
COPY ./scripts/*.sh /

ENTRYPOINT ["/build.sh"]
