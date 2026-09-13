# Brazilian Theme Parks — Formal Employment Analysis (2020–2024)

**Parques Temáticos Brasileiros — Análise do Emprego Formal (2020–2024)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

This repository contains the SQL queries, R scripts, and data pipeline used in the paper:

> **"Theme Parks as Labor Markets: Territorial Specialization, Dual Employment Structures, and Wage Inequality in Brazil (2020–2024)"**
> Submitted to the TEAAS Symposium 2026 — Orange County Convention Center, Orlando, FL

The analysis examines 124,265 formal employment records across 469 Brazilian municipalities (CNAE 9321-2/00) using administrative microdata from RAIS and Novo CAGED, accessed via Google BigQuery through the [Base dos Dados](https://basedosdados.org) platform.

---

## Key Findings

- **+70%** growth in active employment (2020–2024)
- **LQ = 379** in Penha/SC (Beto Carrero World) — sector is 379× more concentrated than national average
- **LQ = 181** in Aquiraz/CE (Beach Park)
- **Dual labor market confirmed**: stable core (14–15 months tenure) vs. high-turnover periphery (5.2 months)
- **82%** of racial wage gap unexplained by qualifications (Oaxaca-Blinder decomposition)

---

## Data Sources

| Source | Description | Access |
|--------|-------------|--------|
| RAIS | Relação Anual de Informações Sociais — mandatory formal employment registry | [Base dos Dados](https://basedosdados.org/dataset/br-me-rais) |
| Novo CAGED | Monthly employment flow data | [Base dos Dados](https://basedosdados.org/dataset/br-me-caged) |

**Sectoral filter:** `cnae_2_subclasse = '9321200'`
**Period:** 2020–2024
**BigQuery project:** Replace `YOUR_PROJECT_ID` with your own Google Cloud project ID

---

## Repository Structure
