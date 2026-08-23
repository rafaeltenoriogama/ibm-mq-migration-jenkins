# Laboratório MQ (versão simples) - QM_PROD1/QM_PROD2/QM_PROD3

Sem SSH, sem Dockerfile customizado, sem usuário/senha para gerenciar.
Só duas coisas: **1) sobe os QMs** com docker compose, **2) roda o
Ansible** que fala com os containers via `docker exec`.

## Passo 1 — Instalar o plugin de conexão docker do Ansible

Só uma vez:

```bash
ansible-galaxy collection install community.docker
```

## Passo 2 — Subir os Queue Managers

```bash
cd mq-docker-lab
docker compose up -d
```

Sem build — usa a imagem oficial direto. Acompanhe até subir:

```bash
docker compose logs -f OLD_SERVER1
```

Espere aparecer algo como `Started queue manager`.

## Passo 3 — (opcional) Conferir que os objetos "antigos" existem

```bash
docker exec OLD_SERVER1 bash -c "echo 'DISPLAY QLOCAL(*)' | runmqsc QM_PROD1"
```

## Passo 4 — Rodar a migração de teste

```bash
cd ansible-test
ansible-playbook playbook.yml -e "qm_filter=QM_PROD3"
```

Isso roda, tudo via `docker exec` (sem senha, sem SSH):

1. `dmpmqcfg` dentro do container `OLD_SERVER3` (origem do QM_PROD3)
2. Baixa o dump para o computador local e reenvia pro container `NEW_SERVER3` (destino)
3. `runmqsc QM_PROD3 < arquivo.mqsc` dentro do container de destino

## Passo 5 — Validar

```bash
docker exec NEW_SERVER3 bash -c "echo 'DISPLAY QLOCAL(*)' | runmqsc QM_PROD3"
```

Se aparecerem as mesmas filas do container antigo (`QM_PROD3.BATCH.IN` etc.),
funcionou. Repita para os outros:

```bash
ansible-playbook playbook.yml -e "qm_filter=QM_PROD1"
ansible-playbook playbook.yml -e "qm_filter=QM_PROD2"
```

Ou todos de uma vez, sem `-e "qm_filter=..."`.

## Passo 6 — Recomeçar do zero

```bash
docker compose down -v && docker compose up -d
```

## Por que isso é diferente do projeto de produção?

Esse lab usa **conexão docker** (`docker exec`) porque os "servidores"
são containers na sua máquina — não faz sentido montar SSH só para
simular. Nos servidores reais (`mq-migration-ansible`), a conexão é
**SSH de verdade**, com usuário/senha via vault, porque é assim que
você acessa os servidores `dom101.prdres` e `prv.cloud`.

A única peça que muda de mecanismo entre os dois projetos é a
**transferência do arquivo**: em produção é `scp` direto
servidor-a-servidor (sem passar pela sua máquina); aqui no lab é
`fetch` + `copy` do Ansible (passa pelo nó de controle), porque é
o jeito simples de mover arquivo entre dois containers via `docker exec`.
O resto — `dmpmqcfg` e `runmqsc` — é idêntico nos dois.

## Troubleshooting

- **`docker compose up` falha ao puxar a imagem**: talvez precise de
  `docker login icr.io`, dependendo da política de acesso da sua
  organização.
- **`unable to find container` no Ansible**: confira se o nome do
  container no `docker compose ps` bate exatamente com o hostname
  no `inventory.ini` (eles precisam ser iguais).
- **Erro de "connection plugin not found"**: rode de novo o
  `ansible-galaxy collection install community.docker` do Passo 1.

## Migrar só alguns tipos de objeto (útil para debug)

Por padrão o playbook migra tudo (channel, queue, topic, sub, listener,
authinfo). Para migrar só um subconjunto, use `object_filter`:

```bash
# só as filas
ansible-playbook playbook.yml -e "qm_filter=QM_PROD1" -e "object_filter=queue"

# filas e canais
ansible-playbook playbook.yml -e "qm_filter=QM_PROD1" -e "object_filter=queue,channel"

# só tópicos e subscrições
ansible-playbook playbook.yml -e "qm_filter=QM_PROD1" -e "object_filter=topic,sub"
```

Valores aceitos: `channel`, `queue`, `topic`, `sub`, `listener`, `authinfo`.
