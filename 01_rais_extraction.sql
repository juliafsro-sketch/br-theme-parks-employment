-- ================================================
-- Brazilian Theme Parks — Formal Employment Analysis
-- SQL Query 01: RAIS Extraction
-- Source: Base dos Dados / Google BigQuery
-- CNAE 9321-2/00: Amusement and Theme Parks
-- Period: 2020–2024
-- ================================================
-- Replace YOUR_PROJECT_ID with your Google Cloud project ID
-- Run in Google BigQuery console or via basedosdados R package

SELECT
  ano,
  id_municipio,
  sigla_uf,
  cnae_2_subclasse,
  sexo,
  idade,
  grau_instrucao_apos_2005,
  raca_cor,
  cbo_2002,
  vinculo_ativo_3112,
  tipo_vinculo,
  mes_admissao,
  mes_desligamento,
  tempo_emprego,
  valor_remuneracao_media,
  valor_remuneracao_media_sm,
  tamanho_estabelecimento,
  natureza_juridica

FROM `basedosdados.br_me_rais.microdados_vinculos`

WHERE
  cnae_2_subclasse = '9321200'
  AND ano BETWEEN 2020 AND 2024

-- Optional: add ORDER BY for reproducibility
ORDER BY ano, id_municipio
