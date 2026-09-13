-- ================================================
-- Brazilian Theme Parks — Formal Employment Analysis
-- SQL Query 03: Total Employment by Municipality
-- Used for Location Quotient (LQ) calculation denominator
-- Source: Base dos Dados / Google BigQuery
-- Period: 2020–2024
-- ================================================
-- NOTE: This query runs on the FULL RAIS table (all sectors)
-- It may process several TB of data — check BigQuery costs before running
-- Estimated cost: ~$5-10 USD depending on project tier

SELECT
  ano,
  id_municipio,
  sigla_uf,
  COUNT(*) AS total_empregos_municipio

FROM `basedosdados.br_me_rais.microdados_vinculos`

WHERE ano BETWEEN 2020 AND 2024

GROUP BY ano, id_municipio, sigla_uf

ORDER BY ano, id_municipio
