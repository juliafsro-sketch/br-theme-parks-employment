Brazilian Theme Parks - Formal Employment Analysis (2020–2024)

Parques Temáticos Brasileiros - Análise do Emprego Formal (2020–2024)

License: MIT

Overview

This repository contains the SQL queries, R scripts, and data pipeline used in the paper:

"Theme Parks as Labor Markets: Territorial Specialization, Dual Employment Structures, and Wage Inequality in Brazil (2020–2024)"
Submitted to the TEAAS Symposium 2026 — Orange County Convention Center, Orlando, FL

The analysis examines 124,265 formal employment records across 469 Brazilian municipalities (CNAE 9321-2/00) using administrative microdata from RAIS and Novo CAGED, accessed via Google BigQuery through the Base dos Dados platform.

Key Findings
+70% growth in active employment (2020–2024)
LQ = 379 in Penha/SC (Beto Carrero World) — sector is 379× more concentrated than national average
LQ = 181 in Aquiraz/CE (Beach Park)
Dual labor market confirmed: stable core (14–15 months tenure) vs. high-turnover periphery (5.2 months)
82% of racial wage gap unexplained by qualifications (Oaxaca-Blinder decomposition)
Data Sources
Source	Description	Access
RAIS	Relação Anual de Informações Sociais — mandatory formal employment registry	Base dos Dados
Novo CAGED	Monthly employment flow data	Base dos Dados

Sectoral filter: cnae_2_subclasse = '9321200'
Period: 2020–2024
BigQuery project: Replace YOUR_PROJECT_ID with your own Google Cloud project ID

Repository Structure
br-theme-parks-employment/
├── README.md
├── LICENSE
├── sql/
│   ├── 01_rais_extraction.sql
│   ├── 02_caged_extraction.sql
│   └── 03_total_employment.sql
├── R/
│   ├── mestrado_parques_completo.R
│   └── graficos_finais.R
└── outputs/
    └── README.md
How to Reproduce
Prerequisites
r
install.packages(c(
  "tidyverse", "basedosdados", "geobr", "sf",
  "patchwork", "viridis", "oaxaca"
))
Setup
Create a Google Cloud project at console.cloud.google.com
Enable the BigQuery API
Add the Base dos Dados project to your BigQuery interface
Replace YOUR_PROJECT_ID in the scripts with your project ID
Run
r
basedosdados::set_billing_id("YOUR_PROJECT_ID")
source("R/mestrado_parques_completo.R")
Indicators Calculated
Indicator	Description
LQ	Location Quotient — municipal sectoral specialization
HHI	Herfindahl-Hirschman Index — national territorial concentration
Oaxaca-Blinder	Racial wage gap decomposition
Kruskal-Wallis	Tenure differences by occupation
Mann-Whitney	Gender wage gap test
Citation
[Author]. (2026). Theme Parks as Labor Markets: Territorial Specialization,
Dual Employment Structures, and Wage Inequality in Brazil (2020–2024).
TEAAS Symposium 2026, Orlando, FL.
GitHub: https://github.com/juliafsro-sketch/br-theme-parks-employment
License

MIT License — see LICENSE for details.

Contact

For questions about the methodology or data pipeline, please open an issue in this repository.
