cat << 'EOF' > 07_reset_ambiente.sql
-- ============================================================
-- SCRIPT 07: RESET - Destruição Controlada do Laboratório
-- ============================================================

DROP TABLE IF EXISTS logs_autenticacao;

-- Executar como superusuário (postgres):
-- DROP DATABASE IF EXISTS empresa_secops;
-- DROP USER IF EXISTS analista_junior;
EOF