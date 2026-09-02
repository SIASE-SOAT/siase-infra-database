# ADR-001 — Escolha do PostgreSQL como banco de dados

**Status:** Aceito
**Data:** 2026
**Repositorio:** siase-infra-database

## Contexto

O sistema SIASE precisa de um banco de dados relacional para armazenar clientes, veiculos, ordens de servico, pecas, servicos e pagamentos. Os dados sao fortemente relacionados e exigem consistencia transacional (ACID). O volume esperado e de medio porte, com picos de carga em horarios de atendimento da oficina.

## Decisao

Adotar **PostgreSQL 16** como banco de dados principal, provisionado via **AWS RDS** gerenciado.

## Justificativa

- **ACID completo:** transacoes com isolamento garantido, essencial para operacoes financeiras (pagamentos) e controle de estoque (pecas).
- **Maturidade:** banco open-source com mais de 35 anos de desenvolvimento ativo, amplamente adotado em sistemas corporativos.
- **Suporte a JSON/JSONB:** permite armazenar dados semi-estruturados sem necessidade de banco secundario.
- **pg_stat_statements:** extensao nativa para monitoramento de queries lentas, habilitada no parameter group.
- **Custo:** open-source, sem licenca proprietaria. O RDS gerenciado elimina overhead operacional de patches, backups e failover.
- **Ecossistema Java:** suporte nativo no Spring Boot via JDBC/JPA, driver oficial `org.postgresql.Driver`, dialeto Hibernate consolidado.
- **Flyway:** migracao de schema versionada e auditavel, compativel nativamente com PostgreSQL.

## Alternativas Consideradas

| Alternativa | Motivo da Rejeicao                                                        |
|-------------|---------------------------------------------------------------------------|
| MySQL       | Menor suporte a tipos avancados; historico de inconsistencias em ACID     |
| MongoDB     | Modelo de dados do SIASE e fortemente relacional; joins sao necessarios   |
| Aurora      | Custo mais elevado; PostgreSQL padrao e suficiente para o volume esperado |

## Consequencias

- O schema e gerenciado via Flyway (migrations V1 a V9 no repositorio `15SOAT`).
- O RDS e provisionado em subnets privadas, sem acesso publico.
- A senha master e gerenciada pelo AWS Secrets Manager com rotacao automatica.
- Indices otimizados foram adicionados na migration V9 para as queries mais frequentes.
