# Guia Definitivo: SQL Básico, SecOps e Administração de PostgreSQL

> **Documentação Consolidada — Aulas 01, 02 e 03**  
> *Foco em Segurança da Informação (SecOps), Modelagem Defensiva, Resolução de Problemas e Boas Práticas.*

---

## 📋 Sumário
1. [Módulo 1: Configuração e Instalação (Como Configurar)](#1-módulo-1-configuração-e-instalação-como-configurar)
   - [1.1 Instalação do PostgreSQL no Linux](#11-instalação-do-postgresql-no-linux)
   - [1.2 Provisionamento Seguro de Usuário e Banco](#12-provisionamento-seguro-de-usuário-e-banco)
   - [1.3 Correção de Permissões no PostgreSQL 15/16 (`schema public`)](#13-correção-de-permissões-no-postgresql-1516-schema-public)
   - [1.4 Configuração do DBeaver e Firewall (`pg_hba.conf`)](#14-configuração-do-dbeaver-e-firewall-pg_hbaconf)
2. [Módulo 2: Modelagem e Criação de Tabelas (Como Fazer)](#2-módulo-2-modelagem-e-criação-de-tabelas-como-fazer)
   - [2.1 Tipagem Defensiva de Dados](#21-tipagem-defensiva-de-dados)
   - [2.2 Criação da Tabela com Restrições (`DDL`)](#22-criação-da-tabela-com-restrições-ddl)
3. [Módulo 3: Manipulação e Consultas Avançadas (DML & DQL)](#3-módulo-3-manipulação-e-consultas-avançadas-dml--dql)
   - [3.1 Inserção Simples e em Lote (*Batch Insert*)](#31-inserção-simples-e-em-lote-batch-insert)
   - [3.2 Testes de Estresse e Travas de Integridade](#32-testes-de-estresse-e-travas-de-integridade)
   - [3.3 Consultas Defensivas (`WHERE`, `LIKE`, `ORDER BY`, `LIMIT`, `OFFSET`)](#33-consultas-defensivas-where-like-order-by-limit-offset)
   - [3.4 Ordem Gramatical Obrigatória do SQL](#34-ordem-gramatical-obrigatória-do-sql)
4. [Módulo 4: Rotinas de Limpeza, Rollback e Purga (Como Desfazer)](#4-módulo-4-rotinas-de-limpeza-rollback-e-purga-como-desfazer)
   - [4.1 Transações de Segurança (`BEGIN` / `ROLLBACK`)](#41-transações-de-segurança-begin--rollback)
   - [4.2 Remoção Controlada de Objetos (`DROP`)](#42-remoção-controlada-de-objetos-drop)
   - [4.3 Purga Total do Sistema (Reset Completo do Ambiente)](#43-purga-total-do-sistema-reset-completo-do-ambiente)

---

## 1. Módulo 1: Configuração e Instalação (Como Configurar)

### 1.1 Instalação do PostgreSQL no Linux
Execute os comandos no terminal Linux para instalar o motor do PostgreSQL e utilitários de segurança:

```bash
# 1. Atualizar listas de pacotes
sudo apt update

# 2. Instalar PostgreSQL e utilitários de auditoria/criptografia (postgresql-contrib)
sudo apt install postgresql postgresql-contrib -y

# 3. Verificar se o serviço está ativo
sudo systemctl status postgresql
```

---

### 1.2 Provisionamento Seguro de Usuário e Banco
Por padrão, o Linux isola o acesso do PostgreSQL no usuário do sistema `postgres`. Acesse o console administrativo master para provisionar a base e a conta de desenvolvimento:

```bash
# Acessar o console como superusuário postgres
sudo -i -u postgres psql
```

Dentro do prompt administrativo (`postgres=#`), execute:

```sql
-- 1. Criar o banco de dados dedicado
CREATE DATABASE <NOME_DO_BANCO>;

-- 2. Criar o usuário de desenvolvimento com senha forte
CREATE USER <SEU_USUARIO_DB> WITH PASSWORD '<SUA_SENHA_SEGURA>';

-- 3. Conceder privilégios de acesso ao banco de dados
GRANT ALL PRIVILEGES ON DATABASE <NOME_DO_BANCO> TO <SEU_USUARIO_DB>;

-- 4. Sair do psql
\q
```

---

### 1.3 Correção de Permissões no PostgreSQL 15/16 (`schema public`)
A partir do PostgreSQL 15, o esquema `public` vem bloqueado por padrão (*hardening*) para usuários comuns. Ao tentar rodar um `CREATE TABLE` como usuário de desenvolvimento, o banco retornará:
> `ERROR: permission denied for schema public`

**Solução:** Entrar no banco desejado com a conta `postgres` e liberar a permissão de criação:

```bash
sudo -i -u postgres psql
```

```sql
-- Conectar ao banco específico
\c <NOME_DO_BANCO>

-- Liberar a criação de objetos no esquema público para o usuário
GRANT CREATE ON SCHEMA public TO <SEU_USUARIO_DB>;

-- Sair
\q
```

---

### 1.4 Configuração do DBeaver e Firewall (`pg_hba.conf`)

#### Diagnóstico de Erro Comum de Rede:
Se o DBeaver retornar o erro:
> `FATAL: no pg_hba.conf entry for host "<IP_LOCAL>", user "<SEU_USUARIO_DB>", database "<NOME_DO_BANCO>"`

Isso significa que o arquivo de firewall interno do PostgreSQL (`pg_hba.conf`) bloqueou a conexão por vir do IP da placa de rede.

#### Soluções:
* **Solução Rápida no DBeaver:** Na janela de conexão do DBeaver, ajuste o campo **Host** para `127.0.0.1` (ou `localhost`).
* **Solução via Arquivo de Configuração do Server (`pg_hba.conf`):**
  1. Edite o arquivo no terminal:
     ```bash
     sudo nano /etc/postgresql/16/main/pg_hba.conf
     ```
  2. Adicione ao final do arquivo a linha de permissão:
     ```text
     host    all             <SEU_USUARIO_DB>    127.0.0.1/32            scram-sha-256
     ```
  3. Recarregue as configurações sem derrubar o servidor:
     ```bash
     sudo systemctl reload postgresql
     ```

---

## 2. Módulo 2: Modelagem e Criação de Tabelas (Como Fazer)

### 2.1 Tipagem Defensiva de Dados
A escolha de tipos de dados é a primeira linha de defesa (*Defense in Depth*) de uma aplicação:

| Tipo de Dado | Quando Usar | Risco/Ataque Evitado |
| :--- | :--- | :--- |
| `VARCHAR(N)` | Textos com tamanho previsível (e-mail, nome, telefone, CEP). | **Evita DoS:** Impedir que o envio de textos gigantes esgote a memória RAM do servidor. |
| `NUMERIC(P, S)` | Valores financeiros e moedas exatas. | **Evita erros de auditoria:** `FLOAT` gera dízimas binárias que fazem centavos desaparecerem. |
| `SERIAL` / `BIGSERIAL` | Chaves primárias numéricas auto-incrementáveis (`1, 2, 3...`). | Garante identificador único e exclusivo para cada linha. |
| `TIMESTAMP WITH TIME ZONE` | Registrar data/hora de eventos e auditorias. | Preserva o fuso horário correto para logs de segurança. |
| `VARCHAR(60)` | Coluna de senha (`senha_hash`). | **Nunca salve senha em texto puro!** Guarde apenas o hash gerado por algoritmos como `bcrypt`. |

---

### 2.2 Criação da Tabela com Restrições (`DDL`)

Conecte-se ao banco e execute o comando de criação com travas de integridade:

```sql
CREATE TABLE usuarios_sistema (
    -- Chave Primária Única Auto-incrementável
    id SERIAL PRIMARY KEY,

    -- Campos Obrigatórios (NOT NULL)
    nome VARCHAR(100) NOT NULL,

    -- Restrição de Unicidade (UNIQUE)
    email VARCHAR(100) UNIQUE NOT NULL,

    -- Armazenamento seguro de Hash de Senha
    senha_hash VARCHAR(60) NOT NULL,

    -- Registro de Data e Fuso Horário
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 3. Módulo 3: Manipulação e Consultas Avançadas (DML & DQL)

### 3.1 Inserção Simples e em Lote (*Batch Insert*)

```sql
-- Inserção de um único registro
INSERT INTO usuarios_sistema (nome, email, senha_hash)
VALUES ('Usuario Exemplo', 'usuario@exemplo.com.br', '$2b$12$eImiTXuWVxfM37uY4JANjO8W1.A91q484$s0hashseguro');

-- Inserção em Lote (Batch Insert - Mais performático)
INSERT INTO usuarios_sistema (nome, email, senha_hash) VALUES 
('Ana Silva', 'ana.silva@exemplo.com.br', '$2b$12$hashSeguroAna123456789012345678901234567890123'),
('Carlos Eduardo', 'carlos.eduardo@empresa.com', '$2b$12$hashSeguroCarlos23456789012345678901234567890'),
('Beatriz Mendes', 'beatriz.mendes@exemplo.com.br', '$2b$12$hashSeguroBia34567890123456789012345678901234');
```

---

### 3.2 Testes de Estresse e Travas de Integridade

1. **Teste de Campo Obrigatório (`NOT NULL`):**
   ```sql
   INSERT INTO usuarios_sistema (nome, email, senha_hash) 
   VALUES (NULL, 'semnome@exemplo.com', '$2b$12$hash12345');
   ```
   *Resultado Esperado:* `ERROR: null value in column "nome" violates not-null constraint`.

2. **Teste de Duplicidade (`UNIQUE`):**
   ```sql
   INSERT INTO usuarios_sistema (nome, email, senha_hash) 
   VALUES ('Impostor', 'usuario@exemplo.com.br', '$2b$12$hash12345');
   ```
   *Resultado Esperado:* `ERROR: duplicate key value violates unique constraint "usuarios_sistema_email_key"`.

---

### 3.3 Consultas Defensivas (`WHERE`, `LIKE`, `ORDER BY`, `LIMIT`, `OFFSET`)

```sql
-- Consulta Filtrada por Sufixo de E-mail
SELECT id, nome, email 
FROM usuarios_sistema 
WHERE email LIKE '%@exemplo.com.br';

-- Consulta com Ordenação e Paginação de Segurança (Evita travar RAM)
SELECT id, nome, email, criado_em
FROM usuarios_sistema
WHERE email LIKE '%@exemplo.com.br'   -- 1. Filtro
ORDER BY criado_em DESC                -- 2. Ordenação (mais recentes primeiro)
LIMIT 10                               -- 3. Máximo de registros retornados
OFFSET 0;                              -- 4. Registros a pular (Paginação)
```

> 🛡️ **Alerta de SecOps (Evitando DoS):** Nunca rode `SELECT *` sem `LIMIT` em produção. Exigir `LIMIT` garante que consultas não sobrecarreguem a memória RAM do servidor web.

---

### 3.4 Ordem Gramatical Obrigatória do SQL
Para evitar erros de sintaxe, escreva as cláusulas na seguinte sequência exata:
1. `SELECT`
2. `FROM`
3. `WHERE`
4. `ORDER BY`
5. `LIMIT`
6. `OFFSET`

---

## 4. Módulo 4: Rotinas de Limpeza, Rollback e Purga (Como Desfazer)

### 4.1 Transações de Segurança (`BEGIN` / `ROLLBACK`)
Sempre utilize blocos de transação ao testar comandos destrutivos ou alterações de dados (`UPDATE` / `DELETE`):

```sql
-- 1. Iniciar o modo de teste seguro
BEGIN;

-- 2. Executar a alteração ou remoção
DELETE FROM usuarios_sistema WHERE id = 1;

-- 3. Caso perceba que cometeu um erro, DESFAÇA IMEDIATAMENTE:
ROLLBACK;

-- 4. Se e somente se o resultado estiver 100% correto, CONFIRME:
-- COMMIT;
```

---

### 4.2 Remoção Controlada de Objetos (`DROP`)

Se você desejar apagar tabelas ou bancos específicos no DBeaver ou psql:

```sql
-- Apagar uma tabela inteira
DROP TABLE IF EXISTS usuarios_sistema;

-- Apagar um banco de dados (Conectado em outro banco)
DROP DATABASE IF EXISTS <NOME_DO_BANCO>;

-- Remover um usuário
DROP USER IF EXISTS <SEU_USUARIO_DB>;
```

---

### 4.3 Purga Total do Sistema (Reset Completo do Ambiente)
Se você precisar desinstalar completamente o PostgreSQL do seu Linux Mint para praticar a instalação do zero:

```bash
# 1. Parar o serviço do banco
sudo systemctl stop postgresql

# 2. Desinstalar software e expurgar configurações
sudo apt purge postgresql postgresql-contrib postgresql-client -y
sudo apt autoremove -y

# 3. Limpar manualmente os diretórios de dados e logs
sudo rm -rf /etc/postgresql/
sudo rm -rf /etc/postgresql-common/
sudo rm -rf /var/lib/postgresql/
sudo rm -rf /var/log/postgresql/

# 4. Remover usuários de sistema invisíveis
sudo deluser postgres
sudo delgroup postgres
```

Para validar a purga total:
```bash
psql --version
# Retorno esperado: command not found
```
