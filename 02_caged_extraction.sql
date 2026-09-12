-- ================================================
-- Brazilian Theme Parks — Formal Employment Analysis
-- SQL Query 02: Novo CAGED Extraction
-- Source: Base dos Dados / Google BigQuery
-- CNAE 9321-2/00: Amusement and Theme Parks
-- Period: 2020–2024
-- ================================================

SELECT
  ano,
  mes,
  id_municipio,
  sigla_uf,
  cnae_2_subclasse,
  sexo,
  idade,
  grau_instrucao,
  raca_cor,
  cbo_2002,
  tipo_movimentacao_desagregado,
  salario_mensal,
  tipo_estabelecimento

FROM `basedosdados.br_me_novo_caged.microdados_movimentacao`

WHERE
  cnae_2_subclasse = '9321200'
  AND ano BETWEEN 2020 AND 2024

ORDER BY ano, mes, id_municipio
