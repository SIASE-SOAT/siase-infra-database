# RFC-001 — Modelo Relacional e Justificativa do Schema

**Status:** Implementado
**Data:** 2026
**Repositorio:** siase-infra-database / 15SOAT

## Resumo

Este documento descreve o modelo relacional do SIASE, as decisoes de design do schema, os relacionamentos entre entidades e as otimizacoes de performance aplicadas.

## Modelo Entidade-Relacionamento

```
┌──────────────┐       ┌──────────────────┐       ┌───────────────┐
│   usuarios   │       │     clientes     │       │   veiculos    │
│──────────────│       │──────────────────│       │───────────────│
│ id (PK)      │       │ id (PK)          │       │ id (PK)       │
│ username     │       │ nome             │       │ placa (UQ)    │
│ password     │       │ documento (UQ)   │       │ marca         │
│ created_at   │       │ tipo_pessoa      │       │ modelo        │
│ updated_at   │       │ email            │       │ ano           │
└──────────────┘       │ telefone         │       │ cliente_id(FK)│
                       │ ativo            │       │ created_at    │
                       │ created_at       │       │ updated_at    │
                       │ updated_at       │       └──────┬────────┘
                       └────────┬─────────┘              │
                                │                        │
                       ┌────────▼────────────────────────▼──────┐
                       │           ordens_de_servico            │
                       │────────────────────────────────────────│
                       │ id (PK)                                │
                       │ numero (UQ)                            │
                       │ status (ENUM)                          │
                       │ valor_total                            │
                       │ valor_pecas                            │
                       │ valor_servicos                         │
                       │ cliente_id (FK → clientes)             │
                       │ veiculo_id (FK → veiculos)             │
                       │ created_at / updated_at                │
                       └──────────┬─────────────────────────────┘
                                  │
               ┌──────────────────┼─────────────────┐
               │                  │                 │
    ┌──────────▼──────┐  ┌────────▼────────┐  ┌─────▼──────────┐
    │   itens_peca    │  │  itens_servico  │  │  pagamentos    │
    │─────────────────│  │─────────────────│  │────────────────│
    │ id (PK)         │  │ id (PK)         │  │ id (PK)        │
    │ ordem_id (FK)   │  │ ordem_id (FK)   │  │ ordem_id (FK)  │
    │ peca_id (FK)    │  │ servico_id (FK) │  │ forma_pagamento│
    │ quantidade      │  │ preco_unitario  │  │ valor          │
    │ preco_unitario  │  │ iniciado_em     │  │ status         │
    │ created_at      │  │ finalizado_em   │  │ created_at     │
    └────────┬────────┘  └────────┬────────┘  └────────────────┘
             │                    │
    ┌────────▼────────┐  ┌────────▼────────┐
    │     pecas       │  │    servicos     │
    │─────────────────│  │─────────────────│
    │ id (PK)         │  │ id (PK)         │
    │ nome            │  │ nome            │
    │ codigo (UQ)     │  │ descricao       │
    │ preco_unitario  │  │ preco           │
    │ estoque_atual   │  │ ativo           │
    │ estoque_minimo  │  │ created_at      │
    │ ativo           │  │ updated_at      │
    │ created_at      │  └────────┬────────┘
    └─────────────────┘           │
                                  │
                       ┌──────────▼──────────┐
                       │   servico_insumos   │
                       │─────────────────────│
                       │ servico_id (FK, PK) │
                       │ peca_id (FK, PK)    │
                       │ quantidade          │
                       └─────────────────────┘

    ┌──────────────────────────────────────────┐
    │             agendamentos                 │
    │──────────────────────────────────────────│
    │ id (PK)                                  │
    │ cliente_id (FK → clientes)               │
    │ veiculo_id (FK → veiculos)               │
    │ data_hora                                │
    │ status (ENUM)                            │
    │ observacoes                              │
    │ created_at / updated_at                  │
    └──────────────────────────────────────────┘
```

## Decisoes de Design

### Identificadores UUID

Todas as entidades usam `UUID` como chave primaria. Isso evita enumeracao sequencial de recursos via API, melhora a seguranca e facilita a geracao de IDs no lado da aplicacao sem dependencia do banco.

### Numero da OS como identificador publico

A `OrdemDeServico` possui dois identificadores:
- `id` (UUID): chave primaria interna, usada nas APIs administrativas autenticadas.
- `numero` (String unica): identificador legivel pelo cliente (ex: `OS-2024-00001`), exposto no portal publico de acompanhamento sem autenticacao.

Essa separacao evita que o cliente precise conhecer UUIDs internos.

### Controle de Estoque na Peca

O campo `estoque_atual` e decrementado atomicamente quando uma peca e adicionada a uma OS. A validacao de estoque suficiente ocorre no use case `AdicionarPecaUC` antes da persistencia, evitando race conditions em operacoes concorrentes.

### Timestamps de Execucao em ItemServico

Os campos `iniciado_em` e `finalizado_em` em `itens_servico` permitem calcular o tempo real de execucao de cada servico. Esses dados alimentam a metrica `siase.execucao.item.tempo` exposta via Micrometer/Prometheus e o painel de tempo medio no Grafana.

### Soft Delete via campo `ativo`

Pecas e servicos nao sao excluidos fisicamente — o campo `ativo = false` os desativa. Isso preserva o historico de ordens de servico que ja referenciavam esses registros.

## Indices Otimizados (Migration V9)

| Tabela                | Indice                                    | Justificativa                                    |
|-----------------------|-------------------------------------------|--------------------------------------------------|
| `clientes`            | `idx_clientes_documento`                  | Busca por CPF/CNPJ na abertura de OS e na Lambda |
| `veiculos`            | `idx_veiculos_placa`                      | Busca por placa na abertura de OS                |
| `ordens_de_servico`   | `idx_os_status`                           | Filtro e ordenacao por status na listagem        |
| `ordens_de_servico`   | `idx_os_numero`                           | Busca publica por numero da OS                   |
| `ordens_de_servico`   | `idx_os_cliente_id`                       | Historico de OS por cliente                      |
| `itens_servico`       | `idx_itens_servico_ordem_id`              | Join na consulta de detalhes da OS               |
| `itens_peca`          | `idx_itens_peca_ordem_id`                 | Join na consulta de detalhes da OS               |

## Migrations Versionadas

| Versao | Descricao                                              |
|--------|--------------------------------------------------------|
| V1     | Criacao do schema inicial                              |
| V2     | Schema principal (clientes, veiculos, OS, pecas)       |
| V3     | Tabela de insumos de servico                           |
| V4     | Tabela de usuarios                                     |
| V5     | Dados de seed para fluxo completo da oficina           |
| V6     | Correcao de constraint de status da OS                 |
| V7     | Timestamps de execucao em itens de servico             |
| V8     | Adicao do status APROVADO no enum de status da OS      |
| V9     | Indices otimizados e constraints de integridade        |
