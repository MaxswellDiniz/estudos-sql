cat << 'EOF' > cadastro_clientes.sql
-- ==========================================
-- PROJETO: Cadastro de Clientes (Estudo)
-- AUTOR: Maxswell Diniz
-- DATA: 2026
-- ==========================================

-- 1. Criação da Tabela com variação.

CREATE TABLE CLIENTES(
	id SERIAL PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	sobrenome VARCHAR(100) NOT NULL,
	email VARCHAR(50) UNIQUE NOT NULL,
	telefone VARCHAR(15)

);

-- 2. Inserção de dados de teste (Dados Sintéticos)

INSERT INTO CLIENTES (nome,sobrenome,email,telefone) VALUES ('SeuNome','SeuSobrenome','SeuEmail','(dd) 99999999')

-- 3. Consulta de Verificação

SELECT nome,sobrenome,email,telefone FROM CLIENTES;
