# 🛡️ PostgreSQL SecOps Audit Pipeline

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-blue?logo=postgresql&logoColor=white)
![Linux](https://img.shields.io/badge/Linux_Mint-Supported-green?logo=linuxmint&logoColor=white)
![Security](https://img.shields.io/badge/SecOps-Least_Privilege-red)
![License](https://img.shields.io/badge/License-MIT-yellow)

Pipeline modular de auditoria de segurança e governança de dados em PostgreSQL. O projeto simula o ciclo de vida completo de uma infraestrutura de logs de autenticação corporativa, aplicando **Modelagem Defensiva (DDL)**, **Princípio do Menor Privilégio (PoLP / DCL)**, **Controle Transacional Rígido (TCL)** e **Análise de Incidentes (DQL)**.

---

## 🏛️ Arquitetura do Projeto & Cenário de Negócio

Em ambientes corporativos sujeitos a regulamentações de segurança (LGPD, ISO 27001 e PCI-DSS), tabelas de auditoria não podem ser alteradas sem controle transacional nem acessadas por usuários com privilégios excessivos.

Este repositório implementa uma solução ponta a ponta para registro e investigação de tentativas de acesso, estruturada em scripts SQL modulares numerados sequencialmente para execução automatizada em pipelines de CI/CD.

---

## 📁 Estrutura Modular dos Scripts (`/scripts`)

Os scripts foram organizados no padrão internacional de *database migrations*, garantindo ordem de dependência estrita:

```text
postgres-secops-audit-pipeline/
├── README.md                           <-- Documentação técnica da arquitetura
└── scripts/
    ├── 01_provisionamento_dcl.sql      <-- DCL: Provisionamento do banco, role e permissões
    ├── 02_estrutura_tabelas_ddl.sql    <-- DDL: Tabela de logs com tipagem INET e CHECK
    ├── 03_evolucao_esquema_ddl.sql     <-- DDL: Evolução de esquema via ALTER TABLE
    ├── 04_carga_e_transacoes_dml_tcl.sql<-- DML/TCL: Carga em lote e controle de transação
    ├── 05_consultas_auditoria_dql.sql  <-- DQL: Padrões de busca de incidentes e paginação
    ├── 06_seguranca_revogacao_dcl.sql  <-- DCL: Hardening com REVOKE DELETE e validação
    └── 07_reset_ambiente.sql           <-- RESET: Limpeza total para ambiente de testes
```

---

## 🛠️ Decisões de Engenharia & Boas Práticas

### 1. Tipagem Defensiva de Dados
* **Endereçamento de Rede (`INET`):** Em vez de tratar IPs como texto (`VARCHAR`), utilizou-se o tipo nativo `INET`. Isso garante validação automática de sintaxe IPv4/IPv6 no nível do banco e otimiza a ocupação de espaço em disco.
* **Prevenção de Negação de Serviço (`VARCHAR(N)`):** Limitação estrita no comprimento dos campos de identificação para evitar injeção de grandes volumes de texto que possam esgotar a memória RAM.
* **Auditoria Temporal Criptográfica (`TIMESTAMP WITH TIME ZONE`):** Preservação do fuso horário em todas as entradas de log para auditoria em ambientes distribuídos globalmente.

### 2. Princípio do Menor Privilégio (PoLP - SecOps)
* A aplicação opera sob a role restrita `analista_junior`, sem privilégios administrativos.
* Aplicação da instrução `REVOKE DELETE ON logs_autenticacao FROM analista_junior;` para impedir que contas comprometidas apaguem vestígios de invasão.

### 3. Proteção Transacional (TCL)
* Operações de inserção e atualização em lote são isoladas em blocos `BEGIN; ... COMMIT;`.
* Simulação de testes de estresse com `ROLLBACK;` para garantir a consistência dos dados em cenários de falha.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* Sistema Operacional Linux (Testado em Linux Mint / Ubuntu)
* PostgreSQL 15+ instalado
* Terminal de linha de comando (`psql`) ou DBeaver

### Passo a Passo de Implantação

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/SEU_USUARIO/postgres-secops-audit-pipeline.git
   cd postgres-secops-audit-pipeline/scripts
   ```

2. **Execute os scripts na ordem numérica:**
   ```bash
   # 1. Provisionar Banco e Usuário (como superusuário postgres)
   sudo -i -u postgres psql -f 01_provisionamento_dcl.sql

   # 2. Criar Estrutura e Evolução de Esquema
   psql -U postgres -d empresa_secops -f 02_estrutura_tabelas_ddl.sql
   psql -U postgres -d empresa_secops -f 03_evolucao_esquema_ddl.sql

   # 3. Executar Carga Transacional e Consultas de Auditoria
   psql -U postgres -d empresa_secops -f 04_carga_e_transacoes_dml_tcl.sql
   psql -U postgres -d empresa_secops -f 05_consultas_auditoria_dql.sql

   # 4. Aplicar Hardening de Segurança (REVOKE)
   psql -U postgres -d empresa_secops -f 06_seguranca_revogacao_dcl.sql
   ```

3. **Validação de Bloqueio por Permissão (Teste de Invasão):**
   Ao tentar deletar um registro com a conta `analista_junior`:
   ```sql
   psql -U analista_junior -d empresa_secops -c "DELETE FROM logs_autenticacao WHERE id = 1;"
   ```
   **Retorno esperado do PostgreSQL:**
   ```text
   ERROR: permission denied for table logs_autenticacao
   ```

4. **Reset do Ambiente (Opcional):**
   ```bash
   psql -U postgres -d empresa_secops -f 07_reset_ambiente.sql
   ```

---

## 👨‍💻 Autor

Desenvolvido por **Maxswell Diniz**  
*Estudante de Engenharia de Dados, SQL Avançado & SecOps.*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/seu-linkedin)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/SEU_USUARIO)
```


