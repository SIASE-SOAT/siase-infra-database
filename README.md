# siase-infra-database

> Pos Tech - Software Architecture | FIAP | Fase 3 — Infraestrutura do Banco de Dados Gerenciado

## Descricao da Solucao

Repositorio responsavel pelo provisionamento do banco de dados gerenciado PostgreSQL na AWS, utilizado pela aplicacao SIASE. Toda a infraestrutura e declarada como codigo via Terraform, garantindo reproducibilidade, rastreabilidade e seguranca no ciclo de vida do banco.

## Tecnologias

| Tecnologia       | Versao  | Justificativa                                                                 |
|------------------|---------|-------------------------------------------------------------------------------|
| Terraform        | 1.7+    | Infraestrutura como codigo — provisionamento declarativo e versionado         |
| AWS RDS          | —       | Banco de dados gerenciado com alta disponibilidade, backups e patches         |
| PostgreSQL       | 16      | Banco relacional robusto, ACID, open-source, suporte a JSON e escalavel       |
| AWS KMS          | —       | Criptografia em repouso do volume RDS com rotacao automatica de chaves        |
| AWS Secrets Manager | —   | Gerenciamento seguro da senha master do banco, sem exposicao em variaveis     |
| AWS SSM Parameter Store | — | Compartilhamento de outputs (endpoint, ARN do segredo) entre repositorios  |

### Por que PostgreSQL?

PostgreSQL foi escolhido por ser um banco relacional maduro com suporte a ACID, ideal para sistemas transacionais como atendimentos e execucao de servicos. Oferece excelente desempenho, suporte a JSON/JSONB para dados semi-estruturados, extensibilidade e e open-source, reduzindo custos de licenca. O uso do RDS gerenciado elimina a necessidade de gerenciar patches, backups e failover manualmente.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │                    VPC (lida via SSM)                    │  │
│   │                                                          │  │
│   │   ┌──────────────────┐    ┌──────────────────────────┐   │  │
│   │   │  Security Group  │    │   Security Group (RDS)   │   │  │
│   │   │  (db-clients)    │───►│   porta 5432 apenas      │   │  │
│   │   │  EKS nodes       │    │   de db-clients SG       │   │  │
│   │   └──────────────────┘    └──────────┬───────────────┘   │  │
│   │                                      │                   │  │
│   │   ┌──────────────────────────────────▼────────────────┐  │  │
│   │   │              AWS RDS PostgreSQL 16                │  │  │
│   │   │   Multi-AZ: configuravel | Storage: gp3 + KMS     │  │  │
│   │   │   Backup: retencao configuravel                   │  │  │
│   │   │   Senha master: gerenciada pelo Secrets Manager   │  │  │
│   │   │   Logs: postgresql → CloudWatch                   │  │  │
│   │   │   pg_stat_statements habilitado                   │  │  │
│   │   └───────────────────────────────────────────────────┘  │  │
│   │                                                          │  │
│   │   Subnets privadas (lidas via SSM)                       │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   SSM Parameter Store (outputs publicados apos apply):          │
│   /siase/production/db-endpoint                                 │
│   /siase/production/db-name                                     │
│   /siase/production/db-secret-arn                               │
│   /siase/production/db-client-sg-id                             │
└─────────────────────────────────────────────────────────────────┘
```

**Dependencia de ordem:** este repositorio consome parametros SSM publicados pelo `siase-infra-k8s` (VPC, subnets privadas, SG dos nodes EKS). O `siase-infra-k8s` deve ser aplicado primeiro.

## Recursos Criados pelo Terraform

| Recurso                        | Tipo                        | Descricao                                              |
|--------------------------------|-----------------------------|--------------------------------------------------------|
| `aws_kms_key.rds`              | KMS Key                     | Chave de criptografia do volume RDS com rotacao        |
| `aws_kms_alias.rds`            | KMS Alias                   | Alias legivel para a chave KMS                         |
| `aws_security_group.db_clients`| Security Group              | SG compartilhado pelos clientes autorizados do banco   |
| `aws_security_group.rds`       | Security Group              | SG do RDS — aceita apenas trafego do SG db-clients     |
| `aws_db_subnet_group.rds`      | DB Subnet Group             | Subnets privadas para o RDS                            |
| `aws_db_parameter_group.rds`   | DB Parameter Group          | pg_stat_statements + slow query log configurados       |
| `aws_db_instance.rds`          | RDS PostgreSQL 16           | Instancia gerenciada com senha via Secrets Manager     |
| `aws_ssm_parameter.db_endpoint`| SSM Parameter               | Endpoint privado do RDS publicado para outros repos    |
| `aws_ssm_parameter.db_name`    | SSM Parameter               | Nome do banco publicado para outros repos              |
| `aws_ssm_parameter.db_secret_arn` | SSM Parameter            | ARN do segredo da senha master                         |
| `aws_ssm_parameter.db_client_sg_id` | SSM Parameter          | ID do SG db-clients para uso pelo EKS                  |

## Variaveis

| Variavel                | Padrao          | Descricao                                              |
|-------------------------|-----------------|--------------------------------------------------------|
| `aws_region`            | —               | Regiao AWS (obrigatoria)                               |
| `environment`           | `production`    | Ambiente                                               |
| `project_name`          | `siase`         | Prefixo dos recursos                                   |
| `db_name`               | `siase`         | Nome do banco de dados                                 |
| `db_username`           | `siase_master`  | Usuario master do RDS                                  |
| `db_instance_class`     | `db.t3.micro`   | Classe da instancia RDS                                |
| `allocated_storage`     | `20`            | Storage inicial em GB                                  |
| `max_allocated_storage` | `20`            | Storage maximo para autoscaling                        |
| `slow_query_duration_ms`| `1000`          | Threshold de slow query em ms                          |
| `backup_retention_days` | `1`             | Dias de retencao de backup                             |
| `backup_window`         | `03:00-03:30`   | Janela de backup diario                                |
| `maintenance_window`    | `sun:04:00-sun:04:30` | Janela de manutencao semanal                   |
| `monitoring_interval`   | `0`             | Intervalo de Enhanced Monitoring (0 = desabilitado)    |
| `multi_az`              | `false`         | Habilitar Multi-AZ                                     |
| `deletion_protection`   | `false`         | Protecao contra exclusao acidental                     |
| `skip_final_snapshot`   | `true`          | Pular snapshot final ao destruir                       |

## Execucao e Deploy

### Pre-requisitos

- Terraform 1.7+
- AWS CLI configurado com credenciais validas
- `siase-infra-k8s` ja aplicado (publica os parametros SSM necessarios)
- Bucket S3 e tabela DynamoDB para o backend Terraform ja criados

### Aplicar

```bash
# 1. Copiar e ajustar o arquivo de variaveis
cp environments/production.tfvars.example environments/production.tfvars
# Editar production.tfvars com aws_region e demais valores

# 2. Inicializar o backend
terraform init \
  -backend-config="bucket=SEU_BUCKET_TFSTATE" \
  -backend-config="key=siase-infra-database/terraform.tfstate" \
  -backend-config="region=us-east-1"

# 3. Visualizar o plano
terraform plan -var-file=environments/production.tfvars

# 4. Aplicar
terraform apply -var-file=environments/production.tfvars
```

### Validacao local (sem backend)

```bash
terraform init -backend=false
terraform validate
terraform fmt -check
```

### Verificar outputs apos apply

```bash
terraform output db_endpoint
terraform output db_secret_arn
```

## CI/CD

| Workflow           | Gatilho                        | O que faz                                              |
|--------------------|--------------------------------|--------------------------------------------------------|
| `build-test.yml`   | Reutilizavel via workflow_call | `terraform fmt -check`, `init -backend=false`, `validate` |
| `ci.yml`           | Pull Request para main/develop | Chama build-test                                       |
| `deploy-prod.yml`  | Push na main                   | `terraform apply` com credenciais temporarias do Learner Lab |

**Observacao sobre autenticacao AWS:** o Learner Lab nao suporta OIDC. O workflow usa credenciais temporarias (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) que expiram a cada sessao de 4h e precisam ser atualizadas manualmente nos secrets do GitHub.

O `deploy-prod.yml` copia automaticamente o `environments/production.tfvars.example` como `production.tfvars` antes do apply. Ajuste o arquivo de exemplo com os valores corretos antes do deploy.

**GitHub Variables necessarias (Environment `production`):**

| Nome                | Descricao                              |
|---------------------|----------------------------------------|
| `AWS_REGION`        | Regiao AWS                             |
| `TF_STATE_BUCKET`   | Bucket S3 do estado Terraform          |

**GitHub Secrets necessarios:**

| Nome                    | Descricao                                      |
|-------------------------|------------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | Chave de acesso temporaria do Learner Lab      |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta temporaria do Learner Lab        |
| `AWS_SESSION_TOKEN`     | Token de sessao temporario do Learner Lab      |

## Documentacao

- [ADR-001 — Escolha do PostgreSQL como banco de dados](docs/adr/ADR-001-escolha-postgresql.md)
- [ADR-002 — Uso do RDS gerenciado com senha via Secrets Manager](docs/adr/ADR-002-rds-secrets-manager.md)
- [RFC-001 — Modelo relacional e justificativa do schema](docs/rfc/RFC-001-modelo-relacional.md)
