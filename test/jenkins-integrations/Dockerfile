# =========================================================
# Jenkins com Ansible + Docker CLI já instalados, prontos
# para rodar o playbook de migração MQ.
# =========================================================
FROM jenkins/jenkins:lts-jdk17

USER root

# Ansible (para rodar os playbooks) + sshpass (autenticação SSH por
# senha, usada no projeto de produção) + curl (para baixar o Docker CLI).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip ansible sshpass curl && \
    rm -rf /var/lib/apt/lists/*

RUN ansible-galaxy collection install community.docker

# Docker CLI: em vez do pacote "docker.io" do apt (que em algumas
# combinações de imagem base não entrega o binário /usr/bin/docker
# corretamente), baixamos o binário estático oficial da Docker.
# Isso não depende de gerenciador de pacotes nenhum.
ARG DOCKER_CLI_VERSION=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" -o /tmp/docker.tgz && \
    tar xzf /tmp/docker.tgz -C /tmp && \
    mv /tmp/docker/docker /usr/local/bin/docker && \
    chmod +x /usr/local/bin/docker && \
    rm -rf /tmp/docker.tgz /tmp/docker

# Confirma na hora do build que o binário existe e roda
RUN docker --version

# O container do Jenkins precisa acessar o socket do Docker do HOST
# (montado via docker-compose) para poder rodar "docker exec"/"docker cp"
# dentro do lab. Para isso, o usuário "jenkins" precisa pertencer a um
# grupo com o MESMO GID do grupo "docker" do host.
#
# O valor default (999) é o mais comum em distros Linux, mas PODE
# ser diferente na sua máquina - veja o README para descobrir o GID
# certo e passar via --build-arg.
ARG DOCKER_GID=999
RUN groupadd -g ${DOCKER_GID} dockerhost || true && \
    usermod -aG dockerhost jenkins

USER jenkins
