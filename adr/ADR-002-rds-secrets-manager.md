# ADR-002 — Uso do RDS Gerenciado com Senha via Secrets Manager

**Status:** Aceito
**Data:** 2026
**Repositorio:** siase-infra-database

## Contexto

O banco de dados precisa de uma senha de acesso segura. A abordagem inicial seria definir a senha como variavel Terraform e armazena-la em um Secret do GitHub. Porem, isso expoe a senha em logs de CI/CD e no estado Terraform sem criptografia adicional.

## Decisao

Utilizar o recurso `manage_master_user_password = true` do `aws_db_instance`, delegando ao **AWS RDS** a criacao e rotacao automatica da senha master via **AWS Secrets Manager**. O Terraform nao conhece o valor da senha — apenas o ARN do secret e publicado via SSM Parameter Store.

## Justificativa

- **Zero exposicao da senha:** o Terraform nunca recebe ou armazena o valor da senha. O RDS cria o secret diretamente no Secrets Manager.
- **Rotacao automatica:** o RDS pode rodar a senha periodicamente sem intervencao manual.
- **Criptografia:** o secret e criptografado com a chave KMS dedicada (`aws_kms_key.rds`), com rotacao anual habilitada.
- **Compartilhamento seguro:** o ARN do secret e publicado no SSM Parameter Store e consumido pela Lambda de autenticacao e pela aplicacao no EKS, sem que o valor trafegue entre repositorios.
- **Auditoria:** todos os acessos ao secret sao registrados no CloudTrail.

## Alternativas Consideradas

| Alternativa                          | Motivo da Rejeição                                                    |
|--------------------------------------|-----------------------------------------------------------------------|
| Senha em variavel Terraform          | Exposta no estado Terraform e em logs de CI/CD                        |
| Senha em GitHub Secret               | Requer rotacao manual; nao integra com Secrets Manager                |
| AWS Parameter Store (SecureString)   | Menos integrado com RDS; rotacao automatica nao e nativa              |

## Consequencias

- A aplicacao no EKS le as credenciais do banco via Secrets Manager em tempo de execucao.
- A Lambda de autenticacao le o secret via `DB_SECRET_ARN` injetado como variável de ambiente.
- O estado Terraform nao contem a senha em texto claro.
- A chave KMS tem `deletion_window_in_days = 30` para prevenir exclusao acidental.
