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
| Novo CAGED | Monthly employment flow data (admissions and dismissals) | [Base dos Dados](https://basedosdados.org/dataset/br-me-caged) |

**Sectoral filter:** `cnae_2_subclasse = '9321200'` (Amusement and Theme Parks)  
**Period:** 2020–2024  
**BigQuery project:** Replace `YOUR_PROJECT_ID` with your own Google Cloud project ID

---

## Repository Structure

```
br-theme-parks-employment/
│
├── README.md
├── LICENSE
│
├── sql/
│   ├── 01_rais_extraction.sql        # Main RAIS extraction query
│   ├── 02_caged_extraction.sql       # Novo CAGED extraction query
│   └── 03_total_employment.sql       # Total employment for LQ calculation
│
├── R/
│   ├── mestrado_parques_completo.R   # Full analysis script (13 sections)
│   └── graficos_finais.R             # Final publication-ready figures
│
└── outputs/
    └── README.md                     # Description of generated outputs
```

---

## How to Reproduce

### Prerequisites

```r
install.packages(c(
  "tidyverse", "basedosdados", "geobr", "sf",
  "patchwork", "viridis", "oaxaca"
))
```

### Setup

1. Create a Google Cloud project at [console.cloud.google.com](https://console.cloud.google.com)
2. Enable the BigQuery API
3. Add the Base dos Dados project to your BigQuery interface
4. Replace `YOUR_PROJECT_ID` in the scripts with your project ID

### Run

```r
# Set your BigQuery project
basedosdados::set_billing_id("YOUR_PROJECT_ID")

# Run the full analysis
source("R/mestrado_parques_completo.R")
```

---

## Indicators Calculated

| Indicator | Description |
|-----------|-------------|
| **LQ** | Location Quotient — municipal sectoral specialization |
| **HHI** | Herfindahl-Hirschman Index — national territorial concentration |
| **Oaxaca-Blinder** | Racial wage gap decomposition |
| **Kruskal-Wallis** | Non-parametric tenure differences by occupation |
| **Mann-Whitney** | Gender wage gap test |

---

## Citation

If you use this code or data pipeline in your research, please cite:

```
[Author]. (2026). Theme Parks as Labor Markets: Territorial Specialization,
Dual Employment Structures, and Wage Inequality in Brazil (2020–2024).
TEAAS Symposium 2026, Orlando, FL.
GitHub: https://github.com/[username]/br-theme-parks-employment
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contact

For questions about the methodology or data pipeline, please open an issue in this repository.
