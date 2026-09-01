![Display screen page](./resources/readme_cover.png)

# IBM MQ Migration Lab

Ambiente de teste para validar a migração de objetos do IBM MQ (filas,
canais, tópicos, subscrições, listeners e whitelist de IP) de servidores
antigos para novos, usando Ansible — sem precisar tocar em produção.

## Como funciona

```mermaid
flowchart LR
    subgraph Old["QueueManagersOld"]
        A[dmpmqcfg]
    end

    subgraph Ctrl["Ansible"]
        B[playbook.yml]
    end

    subgraph New["QueueManagersNew"]
        C[runmqsc]
    end

    B -->|1. dump| A
    A -->|2. transfer .mqsc| C
    B -->|3. apply| C
```

1. **Dump** — `dmpmqcfg` extrai a configuração do Queue Manager antigo em arquivos `.mqsc`
2. **Transfer** — os arquivos vão direto do servidor antigo para o novo
3. **Apply** — `runmqsc` aplica os arquivos no Queue Manager novo

## Fluxo de uma migração

```mermaid
sequenceDiagram
    participant A as QueueManagersOld
    participant N as Ansible (control node)
    participant B as QueueManagersNew

    N->>A: dmpmqcfg -t channel/queue/topic/sub/listener/authinfo
    A-->>N: arquivos .mqsc gerados
    N->>B: transfere os .mqsc
    N->>B: runmqsc < arquivo.mqsc
    B-->>N: objetos criados
```

## Uso rápido

```bash
# 1. Sobe o ambiente de teste
cd mq-docker-lab
docker compose up -d

# 2. Roda a migração de teste
cd ansible-test
ansible-playbook playbook.yml -e "qm_filter=QueueManagersOld"
```

## Migrando só um tipo de objeto

Útil para testar e debugar isoladamente:

```bash
ansible-playbook playbook.yml -e "qm_filter=QueueManagersOld" -e "object_filter=queue"
ansible-playbook playbook.yml -e "qm_filter=QueueManagersOld" -e "object_filter=queue,channel"
```

Valores aceitos: `channel`, `queue`, `topic`, `sub`, `listener`, `authinfo`.

## Estrutura

```mermaid
flowchart TD
    Root["ibm-mq-migration/"] --> Lab["mq-docker-lab/"]
    Lab --> Compose["docker-compose.yml"]
    Lab --> Mqsc["mqsc-init/ (objetos pré-criados)"]
    Lab --> AnsibleTest["ansible-test/ (playbook + tasks)"]
```

> O projeto de produção (conexão SSH real, senhas via vault) não faz
> parte deste repositório de teste.

---

Written by Rafael Gama
