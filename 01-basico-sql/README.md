# 🛡️ Manual Completo de SQL Básico, Administração & SecOps
> **Projeto Âncora:** Sistema de Gestão de TI (Ativos, Usuários e Infraestrutura)  
> **Filosofia de Aprendizado:** Método *Shokunin* (Artesanato Técnico) & *SecOps* (Segurança Operacional em Primeiro Lugar)

---

## 🏛️ MÓDULO 1 — Arquitetura do Banco, Conexão & Troubleshooting de Rede

### 1.1 Arquitetura do PostgreSQL no Linux
* **SGBD (Sistema de Gerenciamento de Banco de Dados):** Intermediário seguro ("portaria armada") que gerencia o acesso físico aos dados em disco.
* **Isolamento de Processos (Princípio do Menor Privilégio - PoLP):** O PostgreSQL roda sob um usuário de sistema isolado chamado `postgres`, sem acesso de administrador (`root`) ao Linux.
* **Separacao de Responsabilidades:**
  * **Superusuário (`postgres`):** Usado apenas para criar bancos, gerenciar usuários e conceder privilégios.
  * **Usuário de Aplicação (`<SEU_USUARIO_DB>`):** Usuário com privilégios limitados para uso do dia a dia no DBeaver e aplicações.

---

### 1.2 Resolução de Erros de Conexão e Firewall (`pg_hba.conf`)
* **O Problema:** Ao tentar conectar uma ferramenta externa (como DBeaver) usando o IP da placa de rede local (ex: `192.168.x.x`), o banco retorna:
  `FATAL: no pg_hba.conf entry for host "..."`
* **Causa Raiz:** O arquivo `/etc/postgresql/16/main/pg_hba.conf` é o firewall interno do Postgres. Por *hardening* padrão, ele aceita conexões apenas da interface local *loopback* (`127.0.0.1`).
* **A Solução SecOps:** No DBeaver, configure o campo **Host** estritamente para `127.0.0.1` (ou `localhost`), evitando expor a porta 5432 para redes externas desnecessariamente.

---

### 1.3 Resolução de Erros de Permissão no PostgreSQL 16
* **O Problema:** Ao tentar criar tabelas com o usuário de aplicação, o Postgres retorna:
  `ERROR: permission denied for schema public`
* **Causa Raiz:** A partir da versão 15 do PostgreSQL, o esquema público (`public`) vem bloqueado para usuários comuns por motivos de segurança.
* **A Solução:** Entrar como superusuário `postgres` e executar a concessão explícita de permissão:
  ```sql
  -- Acessar o banco de destino
  \c <NOME_DO_BANCO>

  -- Conceder permissão de criação no schema public
  GRANT CREATE ON SCHEMA public TO <SEU_USUARIO_DB>;
  ```

---

## 🏗️ MÓDULO 2 — DDL (Data Definition Language) & Tipagem Defensiva

### 2.1 A Regra de Ouro da Tipagem de Dados
Para escolher a tipagem correta de cada coluna, pergunte-se: **"Vou realizar cálculos matemáticos (soma, média, multiplicação) com esse dado?"**
* **NÃO** $ightarrow$ Use **`VARCHAR`** (Texto), mesmo que o valor contenha apenas números!
* **SIM** $ightarrow$ Use tipos numéricos (**`INTEGER`**, **`NUMERIC`**).

#### Guia de Decisão por Campo:
| Dado | Tipo Correto | Motivo do Tipo |
| :--- | :--- | :--- |
| **Telefone / Celular** | `VARCHAR(15)` | Não faz conta; preserva o zero inicial (`0800`, `011`) e símbolos (`+`, `-`, `()`). |
| **CPF / CNPJ / RG / CEP** | `VARCHAR(14)` / `VARCHAR(9)` | Preserva zeros à esquerda (`01001-000`) e formatos com pontos e traços. |
| **Endereço / Nº Casa** | `VARCHAR(150)` / `VARCHAR(20)`| Números residenciais contêm letras ou complementos (ex: `123-A`, `S/N`, `KM 45`). |
| **Quantidade em Estoque** | `INTEGER` | Contagem inteira usada em somas e subtrações de inventário. |
| **Valores Financeiros** | `NUMERIC(10, 2)` | Garante precisão decimal exata com 2 casas para centavos. **Nunca use `FLOAT`** em finanças (evita dízimas binárias ocultas). |
| **Campos de Entrada (Formulários)**| `VARCHAR(N)` limitado | **Proteção contra DoS:** Impede injeção de arquivos gigabytes que esgotam a memória RAM do servidor. |

---

### 2.2 Comandos DDL de Estrutura e Destruição

```sql
-- 1. Criar a Tabela Principal do Sistema de Gestão de TI
CREATE TABLE ativos_ti (
    id SERIAL PRIMARY KEY,
    nome_equipamento VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL,
    valor NUMERIC(10, 2) NOT NULL
);

-- 2. Modificar Estruturas (ALTER TABLE)
ALTER TABLE ativos_ti ADD COLUMN numero_patrimonio VARCHAR(30) UNIQUE;
ALTER TABLE ativos_ti ALTER COLUMN nome_equipamento TYPE VARCHAR(150);
ALTER TABLE ativos_ti DROP COLUMN numero_patrimonio;

-- 3. Comandos de Destruição e Esvaziamento (DIFERENÇAS CRÍTICAS)
-- Apaga todas as linhas instantaneamente e reseta o ID SERIAL (Estrutura mantida)
TRUNCATE TABLE ativos_ti;

-- Destrói a estrutura da tabela e todos os seus dados no banco
DROP TABLE IF EXISTS ativos_ti;

-- Destrói o BANCO DE DADOS INTEIRO no disco (Executar fora da conexão do banco!)
DROP DATABASE <NOME_DO_BANCO>;
```

---

## 💾 MÓDULO 3 — DML (Data Manipulation Language) & Transações ACID

### 3.1 Inserção de Dados (`INSERT`)

```sql
-- Inserção de Registro Único
INSERT INTO ativos_ti (nome_equipamento, tipo, status, valor)
VALUES ('Dell Latitude 3420', 'Notebook', 'Em Uso', 4500.00);

-- Inserção em Lote (Batch Insert - Alta Performance)
INSERT INTO ativos_ti (nome_equipamento, tipo, status, valor) VALUES
('Servidor Dell PowerEdge R750', 'Servidor', 'Em Uso', 35000.00),
('Switch Cisco SG350', 'Switch', 'Disponivel', 2800.00),
('ThinkPad E14', 'Notebook', 'Manutencao', 4200.00),
('Notebook HP ProBook', 'Notebook', 'Disponivel', 3800.00),
('Firewall Fortigate 60F', 'Seguranca', 'Em Uso', 8500.00);
```

---

### 3.2 A Rede de Proteção de Transações: `BEGIN`, `ROLLBACK` e `COMMIT`
Toda operação manual de alteração (`UPDATE`) ou exclusão (`DELETE`) deve utilizar a trava de transação para evitar perdas catastróficas acidentais por falta da cláusula `WHERE`.

* 🟢 **`BEGIN;`** Abre o "modo rascunho". As alterações ficam isoladas na sua sessão sem gravar no disco.
* 🔴 **`ROLLBACK;`** O "botão de pânico". Apaga o rascunho e restaura os dados ao estado original.
* 🔵 **`COMMIT;`** "Passa a caneta permanente". Grava todas as alterações definitivamente no disco rígido.

#### O Ritual Sagrado dos 4 Passos para Modificações Manuais:
1. Executar **`BEGIN;`**
2. Executar o **`UPDATE`** ou **`DELETE`**
3. Executar o **`SELECT` de conferência ocular** para validar na grade
4. Executar **`COMMIT;`** (se estiver perfeito) ou **`ROLLBACK;`** (se errou a mira)

---

### 3.3 Alteração (`UPDATE`) e Remoção (`DELETE`) Seguras

```sql
-- Exemplo de UPDATE Seguro com a Mira WHERE
BEGIN;

UPDATE ativos_ti 
SET status = 'Manutencao'
WHERE id = 1;

-- Conferência
SELECT * FROM ativos_ti WHERE id = 1;

-- Confirmar gravação
COMMIT;

-- Exemplo de DELETE Seguro com a Mira WHERE
BEGIN;

DELETE FROM ativos_ti 
WHERE id = 3;

-- Conferência
SELECT * FROM ativos_ti WHERE id = 3;

-- Confirmar gravação
COMMIT;
```

---

## 🔍 MÓDULO 4 — DQL (Data Query Language) & Filtros Avançados

### 4.1 Cláusulas Essenciais de Consulta

```sql
-- 1. SELECT com Apelidos de Coluna (AS)
SELECT 
    nome_equipamento AS equipamento,
    valor AS preco
FROM ativos_ti;

-- 2. Filtros Comparativos (WHERE) e Lógicos (AND, OR, NOT)
SELECT * FROM ativos_ti
WHERE tipo = 'Notebook' AND status = 'Em Uso';

-- 3. Intervalo (BETWEEN) e Lista de Valores (IN)
SELECT * FROM ativos_ti
WHERE valor BETWEEN 3000.00 AND 10000.00;

SELECT * FROM ativos_ti
WHERE status IN ('Em Uso', 'Disponivel');

-- 4. Busca por Padrões de Texto (LIKE / ILIKE com Curinga %)
-- LIKE: Diferencia maiúsculas/minúsculas. ILIKE: Ignora case no Postgres.
SELECT * FROM ativos_ti WHERE nome_equipamento ILIKE 'Dell%';    -- Começa com
SELECT * FROM ativos_ti WHERE nome_equipamento ILIKE '%Pad%';     -- Contém
SELECT * FROM ativos_ti WHERE nome_equipamento ILIKE '%Cisco';   -- Termina com

-- 5. Ordenação (ORDER BY ASC/DESC)
SELECT * FROM ativos_ti
ORDER BY valor DESC;

-- 6. Limitação e Paginação (LIMIT e OFFSET - Proteção contra DoS)
SELECT * FROM ativos_ti
ORDER BY valor DESC
LIMIT 2 OFFSET 0; -- Retorna os 2 primeiros (Página 1)
```

---

### 4.2 Ordem Sintática Obrigatória do PostgreSQL
O PostgreSQL exige rigorosamente esta ordem ao montar a query:

```sql
SELECT colunas                   -- 1. O que mostrar
FROM tabela                      -- 2. De onde buscar
WHERE condicoes                  -- 3. Como filtrar
ORDER BY coluna_ordenacao DESC   -- 4. Como ordenar
LIMIT quantidade                 -- 5. Quantos retornar
OFFSET pulo;                     -- 6. Quantos pular
```

---

## 🔑 MÓDULO 5 — Credenciais Sanitizadas do Laboratório Local

* **Host / Servidor:** `127.0.0.1`
* **Porta:** `5432`
* **Usuário de Aplicação:** `<SEU_USUARIO_DB>`
* **Senha:** `<SUA_SENHA_SEGURA>`
* **Bancos de Dados:** `<NOME_DO_BANCO>`
* **Superusuário Linux/Postgres:** `postgres`
