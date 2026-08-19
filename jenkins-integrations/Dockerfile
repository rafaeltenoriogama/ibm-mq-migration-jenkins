# =========================================================
# Jenkins com Ansible + Docker CLI já instalados, prontos
# para rodar o playbook de migração MQ.
# =========================================================
FROM jenkins/jenkins:lts-jdk17

USER root

# Ansible (para rodar os playbooks) + Docker CLI (para falar com o
# daemon do host via socket montado) + sshpass (autenticação SSH
# por senha, usada no projeto de produção).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip ansible sshpass docker.io && \
    rm -rf /var/lib/apt/lists/*

RUN ansible-galaxy collection install community.docker

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
