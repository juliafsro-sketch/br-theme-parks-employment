# ================================================
# Parques temáticos como estruturas econômicas e territoriais: uma análise do emprego formal no Brasil (2020–2024) 
# Autor: Júlia Ribeiro
# Script completo — download, análise, gráficos e testes
# ================================================
# Estrutura:
# 00. Pacotes e configurações
# 01. Download dos dados (RAIS e CAGED)
# 02. Tema e cores padrão
# 03. Análises descritivas — RAIS
# 04. Sazonalidade — RAIS e CAGED
# 05. Perfil dos trabalhadores
# 06. Estabelecimentos
# 07. Módulo 4 — QL e HHI
# 08. Cruzamentos analíticos
# 09. Mapas
# 10. Testes estatísticos
# 11. Análise de robustez longitudinal
# ================================================

# ------------------------------------------------
# 00. PACOTES E CONFIGURAÇÕES
# ------------------------------------------------
library(tidyverse)
library(basedosdados)
library(geobr)
library(patchwork)
library(viridis)
library(sf)

# Configurar projeto BigQuery
set_billing_id("mestrado-rais-498203")

# ------------------------------------------------
# 01. DOWNLOAD DOS DADOS
# ------------------------------------------------

# RAIS — microdados de vínculos (CNAE 9321200, 2020-2024)
query_rais <- "
  SELECT *
  FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE cnae_2_subclasse = '9321200'
  AND ano BETWEEN 2020 AND 2024
"
df <- read_sql(query_rais, billing_project_id = "mestrado-rais-498203")

# Salvar dados brutos
saveRDS(df, "~/mestrado_parques/dados/brutos/rais_parques_2020_2024.rds")

# CAGED — microdados de movimentação (CNAE 9321200, 2020-2024)
query_caged <- "
  SELECT *
  FROM `basedosdados.br_me_caged.microdados_movimentacao`
  WHERE cnae_2_subclasse = '9321200'
  AND ano BETWEEN 2020 AND 2024
"
df_caged <- read_sql(query_caged, billing_project_id = "mestrado-rais-498203")

# Salvar dados brutos
saveRDS(df_caged, "~/mestrado_parques/dados/brutos/caged_parques_2020_2024.rds")

# Emprego total por município (para cálculo do QL)
query_total <- "
  SELECT id_municipio, ano, COUNT(*) as total_empregos
  FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE ano BETWEEN 2020 AND 2024
  GROUP BY id_municipio, ano
"
df_total <- read_sql(query_total, billing_project_id = "mestrado-rais-498203")

# Tabela de municípios (geobr)
municipios <- read_municipality(year = 2020, showProgress = FALSE) %>%
  as.data.frame() %>%
  select(code_muni, name_muni) %>%
  mutate(id_municipio = as.character(code_muni))

# ------------------------------------------------
# CARREGAR DADOS SALVOS (usar após primeiro download)
# ------------------------------------------------
# df       <- readRDS("~/mestrado_parques/dados/brutos/rais_parques_2020_2024.rds")
# df_caged <- readRDS("~/mestrado_parques/dados/brutos/caged_parques_2020_2024.rds")

# ------------------------------------------------
# 02. TEMA E CORES PADRÃO
# ------------------------------------------------
tema_dissertacao <- theme_minimal(base_family = "Helvetica") +
  theme(
    plot.title       = element_text(size = 13, face = "bold", color = "#1a1a1a",
                                    margin = margin(b = 10)),
    plot.subtitle    = element_text(size = 11, color = "#444444",
                                    margin = margin(b = 10)),
    axis.title       = element_text(size = 10, color = "#333333"),
    axis.text        = element_text(size = 9,  color = "#444444"),
    axis.line        = element_line(color = "#cccccc"),
    panel.grid.major = element_line(color = "#eeeeee", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    legend.title     = element_text(size = 9, face = "bold"),
    legend.text      = element_text(size = 9),
    legend.position  = "bottom",
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin      = margin(15, 15, 15, 15)
  )

cor_pos <- "#f89540"
cor_neg <- "#7201a8"

# ------------------------------------------------
# 03. ANÁLISES DESCRITIVAS — RAIS
# ------------------------------------------------

# Vínculos por estado
df %>%
  group_by(sigla_uf) %>%
  summarise(total_vinculos = n()) %>%
  arrange(desc(total_vinculos)) %>%
  ggplot(aes(x = reorder(sigla_uf, total_vinculos), y = total_vinculos,
             fill = total_vinculos)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  coord_flip() +
  labs(title = "Vínculos formais em parques temáticos por estado",
       subtitle = "Brasil, 2020–2024",
       x = "Estado", y = "Total de vínculos") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g01_vinculos_por_estado.png",
       width = 10, height = 7, dpi = 300)

# Top 20 municípios
df_municipios <- df %>%
  group_by(id_municipio, sigla_uf) %>%
  summarise(total_vinculos = n(), .groups = "drop") %>%
  arrange(desc(total_vinculos)) %>%
  left_join(municipios, by = "id_municipio") %>%
  select(name_muni, sigla_uf, total_vinculos)

df_municipios %>%
  slice_head(n = 20) %>%
  ggplot(aes(x = reorder(name_muni, total_vinculos), y = total_vinculos,
             fill = total_vinculos)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  coord_flip() +
  labs(title = "Top 20 municípios — vínculos formais em parques temáticos",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "Total de vínculos") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g02_top20_municipios.png",
       width = 10, height = 7, dpi = 300)

# Evolução anual
df %>%
  count(ano) %>%
  ggplot(aes(x = as.numeric(ano), y = n)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = n), vjust = -0.8, size = 3.5) +
  labs(title = "Evolução anual dos vínculos formais",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Total de vínculos") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g03_evolucao_anual.png",
       width = 8, height = 6, dpi = 300)

# Vínculos ativos em 31/12
df %>%
  dplyr::filter(vinculo_ativo_3112 == "1") %>%
  group_by(ano) %>%
  summarise(vinculos_ativos = n()) %>%
  ggplot(aes(x = as.numeric(ano), y = vinculos_ativos)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = vinculos_ativos), vjust = -0.8, size = 3.5) +
  labs(title = "Vínculos ativos em 31/12",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Vínculos ativos") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g04_vinculos_ativos_3112.png",
       width = 8, height = 6, dpi = 300)

# Municípios com parques ativos
df %>%
  dplyr::filter(vinculo_ativo_3112 == "1") %>%
  group_by(ano, id_municipio) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(ano) %>%
  summarise(municipios = n_distinct(id_municipio)) %>%
  ggplot(aes(x = as.numeric(ano), y = municipios)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = municipios), vjust = -0.8, size = 3.5) +
  labs(title = "Municípios com parques ativos em 31/12",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Nº de municípios") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g05_municipios_ativos.png",
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# 04. SAZONALIDADE — RAIS E CAGED
# ------------------------------------------------

# Admissões por mês (nacional)
df %>%
  dplyr::filter(!is.na(mes_admissao), mes_admissao > 0) %>%
  group_by(mes_admissao) %>%
  summarise(total_admissoes = n()) %>%
  mutate(mes_nome = factor(mes_admissao,
                           labels = c("Jan","Fev","Mar","Abr","Mai","Jun",
                                      "Jul","Ago","Set","Out","Nov","Dez"))) %>%
  ggplot(aes(x = mes_nome, y = total_admissoes, fill = total_admissoes)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  labs(title = "Admissões por mês — parques temáticos no Brasil",
       subtitle = "Brasil, 2020–2024",
       x = "Mês", y = "Total de admissões") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g06_admissoes_por_mes.png",
       width = 10, height = 6, dpi = 300)

# Sazonalidade por cluster
df %>%
  dplyr::filter(!is.na(mes_admissao), mes_admissao > 0) %>%
  dplyr::filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
  group_by(sigla_uf, mes_admissao) %>%
  summarise(total_admissoes = n(), .groups = "drop") %>%
  mutate(mes_nome = factor(mes_admissao,
                           labels = c("Jan","Fev","Mar","Abr","Mai","Jun",
                                      "Jul","Ago","Set","Out","Nov","Dez"))) %>%
  ggplot(aes(x = mes_nome, y = total_admissoes, group = sigla_uf,
             color = sigla_uf, linetype = sigla_uf)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  scale_color_viridis(option = "plasma", discrete = TRUE) +
  labs(title = "Sazonalidade das admissões por cluster",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "Total de admissões",
       color = "Estado", linetype = "Estado") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g07_sazonalidade_cluster.png",
       width = 10, height = 6, dpi = 300)

# Saldo mensal CAGED
df_caged %>%
  group_by(ano, mes) %>%
  summarise(saldo = sum(saldo_movimentacao), .groups = "drop") %>%
  mutate(data = as.Date(paste(ano, mes, "01", sep = "-"))) %>%
  ggplot(aes(x = data, y = saldo, fill = saldo > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = cor_pos, "FALSE" = cor_neg)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  labs(title = "Saldo mensal de empregos",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "Saldo (admissões - desligamentos)") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g28_saldo_mensal_caged.png",
       width = 10, height = 6, dpi = 300)

# Saldo anual CAGED
saldos <- df_caged %>%
  group_by(ano) %>%
  summarise(saldo_anual = sum(saldo_movimentacao))

saldos %>%
  ggplot(aes(x = as.numeric(ano), y = saldo_anual, fill = saldo_anual > 0)) +
  geom_col() +
  geom_text(aes(label = saldo_anual,
                vjust = ifelse(saldo_anual > 0, -0.5, 1.5)), size = 3.5) +
  scale_fill_manual(values = c("TRUE" = cor_pos, "FALSE" = cor_neg)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  labs(title = "Saldo anual de empregos",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Saldo") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g29_saldo_anual_caged.png",
       width = 8, height = 6, dpi = 300)

# Saldo anual por cluster
df_caged %>%
  dplyr::filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
  group_by(ano, sigla_uf) %>%
  summarise(saldo = sum(saldo_movimentacao), .groups = "drop") %>%
  ggplot(aes(x = as.numeric(ano), y = saldo, fill = saldo > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = cor_pos, "FALSE" = cor_neg)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  facet_wrap(~sigla_uf, scales = "free_y") +
  labs(title = "Saldo anual por cluster",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Saldo") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g27_saldo_cluster_caged.png",
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# 05. PERFIL DOS TRABALHADORES
# ------------------------------------------------

# Gênero
df %>%
  dplyr::filter(!is.na(sexo)) %>%
  mutate(genero = ifelse(sexo == "1", "Masculino", "Feminino")) %>%
  count(genero) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = genero, y = pct, fill = genero)) +
  geom_col() +
  scale_fill_manual(values = c("Feminino" = cor_neg, "Masculino" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Distribuição por gênero",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g08_genero.png",
       width = 7, height = 6, dpi = 300)

# Idade
df %>%
  dplyr::filter(!is.na(idade), idade > 0, idade < 80) %>%
  mutate(idade = as.numeric(idade)) %>%
  ggplot(aes(x = idade)) +
  geom_histogram(binwidth = 2, fill = cor_pos, color = "white") +
  labs(title = "Distribuição por idade",
       subtitle = "Brasil, 2020–2024",
       x = "Idade", y = "Total de vínculos") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g09_idade.png",
       width = 8, height = 6, dpi = 300)

# Escolaridade
df %>%
  dplyr::filter(!is.na(grau_instrucao_apos_2005)) %>%
  mutate(escolaridade = case_when(
    grau_instrucao_apos_2005 == "1" ~ "Analfabeto",
    grau_instrucao_apos_2005 == "2" ~ "Até 5º ano incompleto",
    grau_instrucao_apos_2005 == "3" ~ "5º ano completo",
    grau_instrucao_apos_2005 == "4" ~ "6º ao 9º ano",
    grau_instrucao_apos_2005 == "5" ~ "Fund. completo",
    grau_instrucao_apos_2005 == "6" ~ "Médio incompleto",
    grau_instrucao_apos_2005 == "7" ~ "Médio completo",
    grau_instrucao_apos_2005 == "8" ~ "Superior incompleto",
    grau_instrucao_apos_2005 == "9" ~ "Superior completo",
    TRUE ~ "Outro"
  )) %>%
  count(escolaridade) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = reorder(escolaridade, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Escolaridade dos trabalhadores",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g10_escolaridade.png",
       width = 9, height = 6, dpi = 300)

# Raça/cor
df %>%
  dplyr::filter(!is.na(raca_cor)) %>%
  mutate(raca = case_when(
    raca_cor == "1" ~ "Indígena",
    raca_cor == "2" ~ "Branca",
    raca_cor == "4" ~ "Preta",
    raca_cor == "6" ~ "Amarela",
    raca_cor == "8" ~ "Parda",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(raca)) %>%
  count(raca) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = reorder(raca, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Distribuição por raça/cor",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g11_raca_cor.png",
       width = 8, height = 6, dpi = 300)

# Remuneração em R$
df %>%
  dplyr::filter(!is.na(valor_remuneracao_media), valor_remuneracao_media > 0,
         valor_remuneracao_media < 10000) %>%
  ggplot(aes(x = valor_remuneracao_media)) +
  geom_histogram(binwidth = 200, fill = cor_pos, color = "white") +
  labs(title = "Distribuição da remuneração média",
       subtitle = "Brasil, 2020–2024 (valores até R$10.000)",
       x = "Remuneração média (R$)", y = "Total de vínculos") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g12_remuneracao_rs.png",
       width = 9, height = 6, dpi = 300)

# Remuneração em salários mínimos
df %>%
  dplyr::filter(!is.na(valor_remuneracao_media_sm), valor_remuneracao_media_sm > 0) %>%
  mutate(faixa_sm = case_when(
    valor_remuneracao_media_sm <= 1   ~ "Até 1 SM",
    valor_remuneracao_media_sm <= 1.5 ~ "1 a 1,5 SM",
    valor_remuneracao_media_sm <= 2   ~ "1,5 a 2 SM",
    valor_remuneracao_media_sm <= 3   ~ "2 a 3 SM",
    valor_remuneracao_media_sm <= 5   ~ "3 a 5 SM",
    TRUE                              ~ "Mais de 5 SM"
  )) %>%
  mutate(faixa_sm = factor(faixa_sm, levels = c("Até 1 SM","1 a 1,5 SM",
                                                  "1,5 a 2 SM","2 a 3 SM",
                                                  "3 a 5 SM","Mais de 5 SM"))) %>%
  count(faixa_sm) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = faixa_sm, y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Remuneração em salários mínimos",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g13_remuneracao_sm.png",
       width = 9, height = 6, dpi = 300)

# Mediana salarial por cluster
df %>%
  dplyr::filter(!is.na(valor_remuneracao_media), valor_remuneracao_media > 0) %>%
  dplyr::filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
  group_by(sigla_uf) %>%
  summarise(mediana_salario = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = reorder(sigla_uf, mediana_salario), y = mediana_salario,
             fill = mediana_salario)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0("R$", round(mediana_salario, 0))),
            hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Mediana salarial por cluster",
       subtitle = "Brasil, 2020–2024",
       x = "Estado", y = "Mediana salarial (R$)") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g14_mediana_salarial_cluster.png",
       width = 8, height = 6, dpi = 300)

# Tempo de emprego
df %>%
  dplyr::filter(!is.na(tempo_emprego), tempo_emprego > 0) %>%
  mutate(faixa = case_when(
    tempo_emprego <= 3  ~ "Até 3 meses",
    tempo_emprego <= 6  ~ "3 a 6 meses",
    tempo_emprego <= 12 ~ "6 a 12 meses",
    tempo_emprego <= 24 ~ "1 a 2 anos",
    tempo_emprego <= 60 ~ "2 a 5 anos",
    TRUE                ~ "Mais de 5 anos"
  )) %>%
  mutate(faixa = factor(faixa, levels = c("Até 3 meses","3 a 6 meses",
                                           "6 a 12 meses","1 a 2 anos",
                                           "2 a 5 anos","Mais de 5 anos"))) %>%
  count(faixa) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = faixa, y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Tempo de emprego",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g15_tempo_emprego.png",
       width = 9, height = 6, dpi = 300)

# Trabalho intermitente
df %>%
  dplyr::filter(!is.na(indicador_trabalho_intermitente)) %>%
  mutate(intermitente = ifelse(indicador_trabalho_intermitente == "1",
                               "Intermitente", "Regular")) %>%
  count(intermitente) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = intermitente, y = pct, fill = intermitente)) +
  geom_col() +
  scale_fill_manual(values = c("Intermitente" = cor_neg, "Regular" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Trabalho intermitente",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g16_trabalho_intermitente.png",
       width = 7, height = 6, dpi = 300)

# Trabalho parcial
df %>%
  dplyr::filter(!is.na(indicador_trabalho_parcial)) %>%
  mutate(parcial = ifelse(indicador_trabalho_parcial == "1",
                          "Parcial", "Regular")) %>%
  count(parcial) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = parcial, y = pct, fill = parcial)) +
  geom_col() +
  scale_fill_manual(values = c("Parcial" = cor_neg, "Regular" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Trabalho parcial",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g17_trabalho_parcial.png",
       width = 7, height = 6, dpi = 300)

# Top 15 ocupações
df %>%
  dplyr::filter(!is.na(cbo_2002)) %>%
  count(cbo_2002) %>%
  arrange(desc(n)) %>%
  slice_head(n = 15) %>%
  mutate(ocupacao = case_when(
    cbo_2002 == "371410" ~ "Recreacionista",
    cbo_2002 == "422105" ~ "Recepcionista",
    cbo_2002 == "514320" ~ "Trab. de limpeza",
    cbo_2002 == "421125" ~ "Operador de caixa",
    cbo_2002 == "513435" ~ "Atend. lanchonete",
    cbo_2002 == "521140" ~ "Vendedor",
    cbo_2002 == "991205" ~ "Manutenção",
    cbo_2002 == "517115" ~ "Vigia/vigilante",
    cbo_2002 == "513405" ~ "Garçom",
    cbo_2002 == "411005" ~ "Aux. administrativo",
    cbo_2002 == "513505" ~ "Barman",
    cbo_2002 == "411010" ~ "Assist. administrativo",
    cbo_2002 == "513205" ~ "Cozinheiro",
    cbo_2002 == "410105" ~ "Aux. de escritório",
    cbo_2002 == "421115" ~ "Bilheteiro",
    TRUE ~ cbo_2002
  )) %>%
  ggplot(aes(x = reorder(ocupacao, n), y = n, fill = n)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = n), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Top 15 ocupações",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "Total de vínculos") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g18_top15_ocupacoes.png",
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# 06. ESTABELECIMENTOS
# ------------------------------------------------

# Tamanho
df %>%
  dplyr::filter(!is.na(tamanho_estabelecimento)) %>%
  mutate(tamanho = case_when(
    tamanho_estabelecimento == "1" ~ "Até 4",
    tamanho_estabelecimento == "2" ~ "5 a 9",
    tamanho_estabelecimento == "3" ~ "10 a 19",
    tamanho_estabelecimento == "4" ~ "20 a 49",
    tamanho_estabelecimento == "5" ~ "50 a 99",
    tamanho_estabelecimento == "6" ~ "100 a 249",
    tamanho_estabelecimento == "7" ~ "250 a 499",
    tamanho_estabelecimento == "8" ~ "500 a 999",
    tamanho_estabelecimento == "9" ~ "1000 ou mais",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(tamanho)) %>%
  mutate(tamanho = factor(tamanho, levels = c("Até 4","5 a 9","10 a 19",
                                               "20 a 49","50 a 99","100 a 249",
                                               "250 a 499","500 a 999","1000 ou mais"))) %>%
  count(tamanho) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = tamanho, y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Tamanho dos estabelecimentos",
       subtitle = "Brasil, 2020–2024",
       x = "Vínculos", y = "%") +
  tema_dissertacao +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")
ggsave("~/mestrado_parques/graficos/g19_tamanho_estabelecimento.png",
       width = 10, height = 6, dpi = 300)

# Natureza jurídica
df %>%
  dplyr::filter(!is.na(natureza_juridica)) %>%
  mutate(natureza = case_when(
    substr(natureza_juridica, 1, 1) == "1" ~ "Administração pública",
    substr(natureza_juridica, 1, 1) == "2" ~ "Entidades empresariais",
    substr(natureza_juridica, 1, 1) == "3" ~ "Entidades sem fins lucrativos",
    substr(natureza_juridica, 1, 1) == "4" ~ "Pessoas físicas",
    TRUE ~ "Outro"
  )) %>%
  count(natureza) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = reorder(natureza, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Natureza jurídica dos estabelecimentos",
       subtitle = "Brasil, 2020–2024", x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g20_natureza_juridica.png",
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# 07. MÓDULO 4 — QL E HHI
# ------------------------------------------------

# Calcular QL
df_ql <- df %>%
  group_by(id_municipio, ano) %>%
  summarise(emp_setor_muni = n(), .groups = "drop") %>%
  left_join(df_total, by = c("id_municipio","ano")) %>%
  left_join(df %>% group_by(ano) %>%
              summarise(emp_setor_brasil = n(), .groups = "drop"), by = "ano") %>%
  left_join(df_total %>% group_by(ano) %>%
              summarise(emp_total_brasil = sum(total_empregos), .groups = "drop"),
            by = "ano") %>%
  mutate(ql = (emp_setor_muni / total_empregos) /
           (emp_setor_brasil / emp_total_brasil))

# QL Top 15
df_ql %>%
  dplyr::filter(ano == 2024) %>%
  arrange(desc(ql)) %>%
  slice_head(n = 15) %>%
  left_join(municipios, by = "id_municipio") %>%
  ggplot(aes(x = reorder(name_muni, ql), y = ql, fill = ql)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = round(ql, 0)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Quociente Locacional (QL) — Top 15 municípios",
       subtitle = "Brasil, 2024", x = "", y = "QL") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g21_ql_top15.png",
       width = 10, height = 7, dpi = 300)

# HHI
df_hhi <- df %>%
  group_by(ano, id_municipio) %>%
  summarise(emp_muni = n(), .groups = "drop") %>%
  left_join(df %>% group_by(ano) %>%
              summarise(emp_total = n(), .groups = "drop"), by = "ano") %>%
  mutate(s = emp_muni / emp_total) %>%
  group_by(ano) %>%
  summarise(hhi = sum(s^2))

df_hhi %>%
  ggplot(aes(x = as.numeric(ano), y = hhi)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = round(hhi, 4)), vjust = -0.8, size = 3.5) +
  labs(title = "Índice HHI — concentração territorial do emprego",
       subtitle = "Brasil, 2020–2024", x = "Ano", y = "HHI") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g22_hhi.png",
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# 08. CRUZAMENTOS ANALÍTICOS
# ------------------------------------------------

# QL x Salário (2024)
df_ql_salario <- df %>%
  dplyr::filter(ano == 2024, valor_remuneracao_media > 0,
         !is.na(valor_remuneracao_media)) %>%
  group_by(id_municipio) %>%
  summarise(mediana_salario = median(valor_remuneracao_media),
            total_vinculos = n(), .groups = "drop") %>%
  left_join(df_ql %>% dplyr::filter(ano == 2024), by = "id_municipio") %>%
  left_join(municipios, by = "id_municipio") %>%
  dplyr::filter(!is.na(ql), total_vinculos >= 50)

ggplot(df_ql_salario, aes(x = ql, y = mediana_salario)) +
  geom_point(aes(size = total_vinculos, color = mediana_salario), alpha = 0.7) +
  scale_color_viridis(option = "plasma", direction = -1) +
  geom_smooth(method = "lm", color = "#440154", se = TRUE) +
  geom_text(data = df_ql_salario %>% dplyr::filter(ql > 50),
            aes(label = name_muni), vjust = -0.8, size = 3) +
  labs(title = "Especialização (QL) × Remuneração mediana por município",
       subtitle = "Brasil, 2024",
       x = "Quociente Locacional (QL)",
       y = "Mediana salarial (R$)", size = "Vínculos") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g23_ql_vs_salario.png",
       width = 10, height = 7, dpi = 300)

# Desigualdade salarial — gênero e raça
p_genero <- df %>%
  dplyr::filter(!is.na(sexo), valor_remuneracao_media > 0) %>%
  mutate(genero = ifelse(sexo == "1", "Masculino", "Feminino")) %>%
  group_by(genero) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = genero, y = mediana, fill = genero)) +
  geom_col() +
  scale_fill_manual(values = c("Feminino" = cor_neg, "Masculino" = cor_pos)) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))), vjust = -0.5, size = 3.5) +
  labs(title = "Por gênero", x = "", y = "R$") +
  tema_dissertacao + theme(legend.position = "none")

p_raca <- df %>%
  dplyr::filter(!is.na(raca_cor), valor_remuneracao_media > 0) %>%
  mutate(raca = case_when(
    raca_cor == "2" ~ "Branca",
    raca_cor == "4" ~ "Preta",
    raca_cor == "8" ~ "Parda",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(raca)) %>%
  group_by(raca) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = reorder(raca, mediana), y = mediana, fill = mediana)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))), vjust = -0.5, size = 3.5) +
  labs(title = "Por raça/cor", x = "", y = "R$") +
  tema_dissertacao + theme(legend.position = "none")

p_genero + p_raca +
  plot_annotation(title = "Desigualdade salarial — parques temáticos no Brasil",
                  subtitle = "Brasil, 2020–2024")
ggsave("~/mestrado_parques/graficos/g24_desigualdade_salarial.png",
       width = 10, height = 6, dpi = 300)

# Tempo de emprego por ocupação
df %>%
  dplyr::filter(!is.na(tempo_emprego), tempo_emprego > 0) %>%
  mutate(ocupacao = case_when(
    cbo_2002 == "371410" ~ "Recreacionista",
    cbo_2002 == "422105" ~ "Recepcionista",
    cbo_2002 == "514320" ~ "Trab. de limpeza",
    cbo_2002 == "421125" ~ "Operador de caixa",
    cbo_2002 == "513435" ~ "Atend. lanchonete",
    cbo_2002 == "521140" ~ "Vendedor",
    cbo_2002 == "991205" ~ "Manutenção",
    cbo_2002 == "517115" ~ "Vigia/vigilante",
    cbo_2002 == "411005" ~ "Aux. administrativo",
    cbo_2002 == "411010" ~ "Assist. administrativo",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(ocupacao)) %>%
  group_by(ocupacao) %>%
  summarise(mediana_meses = median(tempo_emprego)) %>%
  ggplot(aes(x = reorder(ocupacao, mediana_meses), y = mediana_meses,
             fill = mediana_meses)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = round(mediana_meses, 1)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Tempo mediano de emprego por ocupação",
       subtitle = "Brasil, 2020–2024", x = "", y = "Meses") +
  tema_dissertacao + theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g25_tempo_emprego_ocupacao.png",
       width = 10, height = 7, dpi = 300)

# Escolaridade x Remuneração
df %>%
  dplyr::filter(!is.na(grau_instrucao_apos_2005), valor_remuneracao_media > 0) %>%
  mutate(escolaridade = case_when(
    grau_instrucao_apos_2005 == "1" ~ "Analfabeto",
    grau_instrucao_apos_2005 == "2" ~ "Até 5º ano incompleto",
    grau_instrucao_apos_2005 == "3" ~ "5º ano completo",
    grau_instrucao_apos_2005 == "4" ~ "6º ao 9º ano",
    grau_instrucao_apos_2005 == "5" ~ "Fund. completo",
    grau_instrucao_apos_2005 == "6" ~ "Médio incompleto",
    grau_instrucao_apos_2005 == "7" ~ "Médio completo",
    grau_instrucao_apos_2005 == "8" ~ "Superior incompleto",
    grau_instrucao_apos_2005 == "9" ~ "Superior completo",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(escolaridade)) %>%
  mutate(escolaridade = factor(escolaridade, levels = c(
    "Analfabeto","Até 5º ano incompleto","5º ano completo",
    "6º ao 9º ano","Fund. completo","Médio incompleto",
    "Médio completo","Superior incompleto","Superior completo"
  ))) %>%
  group_by(escolaridade) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = escolaridade, y = mediana, fill = mediana)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))), vjust = -0.5, size = 3.5) +
  labs(title = "Remuneração mediana por escolaridade",
       subtitle = "Brasil, 2020–2024", x = "", y = "R$") +
  tema_dissertacao +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")
ggsave("~/mestrado_parques/graficos/g26_escolaridade_vs_salario.png",
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# 09. MAPAS
# ------------------------------------------------

# Shapefile dos municípios
mapa_municipios <- read_municipality(year = 2020, showProgress = FALSE)

# Mapa de vínculos
df_mapa <- df %>%
  group_by(id_municipio) %>%
  summarise(total_vinculos = n(), .groups = "drop") %>%
  mutate(code_muni = as.numeric(id_municipio))

mapa_vinculos <- mapa_municipios %>%
  left_join(df_mapa, by = "code_muni") %>%
  mutate(total_vinculos = replace_na(total_vinculos, 0))

ggplot(mapa_vinculos) +
  geom_sf(aes(fill = total_vinculos), color = NA) +
  scale_fill_viridis(option = "plasma", direction = -1,
                     name = "Vínculos", trans = "log1p",
                     labels = scales::comma) +
  labs(title = "Vínculos formais em parques temáticos por município",
       subtitle = "Brasil, 2020–2024",
       caption = "Fonte: RAIS/MTE, elaboração própria") +
  tema_dissertacao +
  theme(axis.text = element_blank(), axis.title = element_blank(),
        axis.line = element_blank(), panel.grid = element_blank())
ggsave("~/mestrado_parques/graficos/g30_mapa_vinculos.png",
       width = 10, height = 8, dpi = 300)

# Mapa de QL com clusters identificados
df_mapa_ql <- df_ql %>%
  dplyr::filter(ano == 2024) %>%
  mutate(code_muni = as.numeric(id_municipio))

mapa_ql <- mapa_municipios %>%
  left_join(df_mapa_ql, by = "code_muni")

clusters_destaque <- data.frame(
  name_muni = c("Penha", "Aquiraz", "Gramado", "Caldas Novas",
                "Vinhedo", "Olímpia", "Foz do Iguaçu"),
  lat = c(-26.77, -3.90, -29.37, -17.74, -23.03, -20.73, -25.54),
  lon = c(-48.64, -38.39, -50.87, -48.62, -47.07, -48.91, -54.58),
  hjust = c(1.2, -0.2, 1.2, -0.2, 1.2, 1.2, 1.2),
  vjust = c(0.5, 0.5, 0.5, 0.5, 0.5, -0.8, 0.5)
)

ggplot(mapa_ql) +
  geom_sf(aes(fill = ql), color = NA) +
  scale_fill_viridis(option = "plasma", direction = -1,
                     name = "QL", trans = "log1p", na.value = "#eeeeee") +
  geom_point(data = clusters_destaque, aes(x = lon, y = lat),
             color = "white", size = 2.5, shape = 21,
             fill = "white", stroke = 1) +
  geom_label(data = clusters_destaque,
             aes(x = lon, y = lat, label = name_muni,
                 hjust = hjust, vjust = vjust),
             color = "#1a1a1a", size = 2.8, fontface = "bold",
             fill = "white", alpha = 0.8, linewidth = 0) +
  labs(title = "Especialização territorial — Quociente Locacional por município",
       subtitle = "Brasil, 2024 — clusters principais identificados",
       caption = "Fonte: RAIS/MTE, elaboração própria") +
  tema_dissertacao +
  theme(axis.text = element_blank(), axis.title = element_blank(),
        axis.line = element_blank(), panel.grid = element_blank())
ggsave("~/mestrado_parques/graficos/g32_mapa_ql_clusters.png",
       width = 10, height = 8, dpi = 300)

# ------------------------------------------------
# 10. TESTES ESTATÍSTICOS
# ------------------------------------------------

# Regressão linear simples — QL x salário (2024)
modelo <- lm(mediana_salario ~ ql, data = df_ql_salario)

# Correlação de Spearman
spearman <- cor.test(df_ql_salario$ql, df_ql_salario$mediana_salario,
                     method = "spearman")

# Regressão múltipla — QL + escolaridade + tamanho (2024)
df_reg_mult <- df %>%
  dplyr::filter(ano == 2024, valor_remuneracao_media > 0,
         !is.na(valor_remuneracao_media),
         !is.na(grau_instrucao_apos_2005),
         !is.na(tamanho_estabelecimento)) %>%
  mutate(escolaridade = as.numeric(grau_instrucao_apos_2005),
         tamanho = as.numeric(tamanho_estabelecimento)) %>%
  group_by(id_municipio) %>%
  summarise(mediana_salario = median(valor_remuneracao_media),
            media_escolaridade = mean(escolaridade, na.rm = TRUE),
            media_tamanho = mean(tamanho, na.rm = TRUE),
            total_vinculos = n(), .groups = "drop") %>%
  left_join(df_ql %>% dplyr::filter(ano == 2024), by = "id_municipio") %>%
  dplyr::filter(!is.na(ql))

modelo_mult <- lm(mediana_salario ~ ql + media_escolaridade + media_tamanho,
                  data = df_reg_mult)

# ANOVA — diferença salarial entre clusters (2020-2024)
df_anova <- df %>%
  dplyr::filter(!is.na(valor_remuneracao_media), valor_remuneracao_media > 0) %>%
  dplyr::filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO"))

modelo_anova <- aov(valor_remuneracao_media ~ sigla_uf, data = df_anova)
tukey <- TukeyHSD(modelo_anova)

# Salvar resultados
sink("~/mestrado_parques/outputs/resultados_estatisticos.txt")
cat("=== REGRESSÃO LINEAR SIMPLES — QL x SALÁRIO (2024) ===\n\n")
print(summary(modelo))
cat("\n=== CORRELAÇÃO DE SPEARMAN — QL x SALÁRIO (2024) ===\n\n")
print(spearman)
cat("\n=== REGRESSÃO MÚLTIPLA — QL + ESCOLARIDADE + TAMANHO (2024) ===\n\n")
print(summary(modelo_mult))
cat("\n=== ANOVA — DIFERENÇA SALARIAL ENTRE CLUSTERS (2020-2024) ===\n\n")
print(summary(modelo_anova))
cat("\n=== TUKEY — COMPARAÇÕES PAR A PAR ===\n\n")
print(tukey)
sink()

# ------------------------------------------------
# 11. ANÁLISE DE ROBUSTEZ LONGITUDINAL
# ------------------------------------------------
# Objetivo: verificar se a relação QL x salário é consistente
# ao longo de todos os anos do período (2020-2024)

resultados_anos <- data.frame()

for(ano_i in 2020:2024) {

  df_ano <- df %>%
    dplyr::filter(ano == ano_i, valor_remuneracao_media > 0,
                  !is.na(valor_remuneracao_media)) %>%
    group_by(id_municipio) %>%
    summarise(mediana_salario = median(valor_remuneracao_media),
              total_vinculos = n(), .groups = "drop") %>%
    left_join(df_ql %>% dplyr::filter(ano == ano_i), by = "id_municipio") %>%
    dplyr::filter(!is.na(ql), total_vinculos >= 50)

  modelo_ano <- lm(mediana_salario ~ ql, data = df_ano)
  s <- summary(modelo_ano)

  resultados_anos <- rbind(resultados_anos, data.frame(
    ano = ano_i,
    n_municipios = nrow(df_ano),
    beta_ql = round(coef(modelo_ano)[2], 3),
    erro_padrao = round(coef(summary(modelo_ano))[2, 2], 3),
    t_valor = round(coef(summary(modelo_ano))[2, 3], 3),
    p_valor = round(coef(summary(modelo_ano))[2, 4], 4),
    r_quadrado = round(s$r.squared, 3)
  ))
}

print(resultados_anos)

# Gráfico evolução do coeficiente QL por ano
resultados_anos %>%
  ggplot(aes(x = ano, y = beta_ql)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_errorbar(aes(ymin = beta_ql - erro_padrao,
                    ymax = beta_ql + erro_padrao),
                width = 0.2, color = cor_pos) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  geom_text(aes(label = paste0("β=", beta_ql, "\np=", p_valor)),
            vjust = -0.8, size = 3) +
  labs(title = "Evolução do coeficiente QL × remuneração mediana (2020–2024)",
       subtitle = "Barras de erro indicam ±1 erro padrão",
       x = "Ano", y = "Coeficiente β do QL") +
  tema_dissertacao
ggsave("~/mestrado_parques/graficos/g33_evolucao_coeficiente_ql.png",
       width = 10, height = 7, dpi = 300)

# Salvar resultados longitudinais
sink("~/mestrado_parques/outputs/resultados_longitudinais.txt", append = TRUE)
cat("\n=== ANÁLISE DE ROBUSTEZ — REGRESSÃO QL x SALÁRIO POR ANO ===\n\n")
print(resultados_anos)
sink()

cat("\n✅ Script completo executado com sucesso!\n")
cat("✅ Gráficos salvos em ~/mestrado_parques/graficos/\n")
cat("✅ Resultados estatísticos salvos em ~/mestrado_parques/outputs/\n")

# ------------------------------------------------
# 12. TESTES ADICIONAIS — DESIGUALDADES
# ------------------------------------------------

# B.7 — Mann-Whitney — diferença salarial por gênero
teste_genero <- wilcox.test(valor_remuneracao_media ~ sexo,
                             data = df %>%
                               dplyr::filter(sexo %in% c("1","2"),
                                             valor_remuneracao_media > 0))

# B.8 — Kruskal-Wallis — diferença salarial por raça
teste_raca <- kruskal.test(valor_remuneracao_media ~ raca_cor,
                            data = df %>%
                              dplyr::filter(raca_cor %in% c("2","4","8"),
                                            valor_remuneracao_media > 0))

# B.9 — Kruskal-Wallis — tempo de emprego por ocupação
df_ocup <- df %>%
  dplyr::filter(!is.na(tempo_emprego), tempo_emprego > 0) %>%
  mutate(ocupacao = case_when(
    cbo_2002 == "371410" ~ "Recreacionista",
    cbo_2002 == "422105" ~ "Recepcionista",
    cbo_2002 == "514320" ~ "Trab. de limpeza",
    cbo_2002 == "421125" ~ "Operador de caixa",
    cbo_2002 == "513435" ~ "Atend. lanchonete",
    cbo_2002 == "521140" ~ "Vendedor",
    cbo_2002 == "991205" ~ "Manutenção",
    cbo_2002 == "517115" ~ "Vigia/vigilante",
    cbo_2002 == "411005" ~ "Aux. administrativo",
    cbo_2002 == "411010" ~ "Assist. administrativo",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(ocupacao))

teste_ocupacao <- kruskal.test(tempo_emprego ~ ocupacao, data = df_ocup)

# B.10 — Spearman — escolaridade × salário
teste_escolaridade <- cor.test(as.numeric(df$grau_instrucao_apos_2005),
                                df$valor_remuneracao_media,
                                method = "spearman",
                                use = "complete.obs")

# B.11 — Qui-quadrado — gênero × raça
tabela_genero_raca <- table(df$sexo, df$raca_cor)
teste_chisq <- chisq.test(tabela_genero_raca)

# Salvar todos os resultados
sink("~/mestrado_parques/outputs/resultados_estatisticos.txt", append = TRUE)
cat("\n=== MANN-WHITNEY — DIFERENÇA SALARIAL POR GÊNERO ===\n\n")
print(teste_genero)
cat("\n=== KRUSKAL-WALLIS — DIFERENÇA SALARIAL POR RAÇA ===\n\n")
print(teste_raca)
cat("\n=== KRUSKAL-WALLIS — TEMPO DE EMPREGO POR OCUPAÇÃO ===\n\n")
print(teste_ocupacao)
cat("\n=== SPEARMAN — ESCOLARIDADE × SALÁRIO ===\n\n")
print(teste_escolaridade)
cat("\n=== QUI-QUADRADO — GÊNERO × RAÇA ===\n\n")
print(teste_chisq)
sink()

cat("\n✅ Testes adicionais concluídos e salvos!\n")

# ------------------------------------------------
# 13. OAXACA-BLINDER E INTERSECCIONALIDADE
# ------------------------------------------------

library(oaxaca)
library(viridis)

# B.12 — Decomposição Oaxaca-Blinder — Branco vs Pardo
df_oaxaca <- df %>%
  dplyr::filter(raca_cor %in% c("2","8"),
                valor_remuneracao_media > 0,
                !is.na(grau_instrucao_apos_2005),
                !is.na(tempo_emprego),
                !is.na(idade)) %>%
  mutate(
    branco = ifelse(raca_cor == "2", 1, 0),
    escolaridade = as.numeric(grau_instrucao_apos_2005),
    tempo_emprego_num = as.numeric(tempo_emprego),
    idade_num = as.numeric(idade),
    log_salario = log(valor_remuneracao_media)
  ) %>%
  dplyr::filter(is.finite(log_salario),
                is.finite(escolaridade),
                is.finite(tempo_emprego_num),
                is.finite(idade_num))

resultado_oaxaca <- oaxaca(log_salario ~ escolaridade +
                           tempo_emprego_num + idade_num | branco,
                           data = df_oaxaca,
                           R = 100)

# B.13 — Interseccionalidade — Gênero × Raça
df_intersec <- df %>%
  dplyr::filter(raca_cor %in% c("2","8"),
                sexo %in% c("1","2"),
                valor_remuneracao_media > 0) %>%
  mutate(grupo = case_when(
    sexo == "1" & raca_cor == "2" ~ "Homem branco",
    sexo == "1" & raca_cor == "8" ~ "Homem pardo",
    sexo == "2" & raca_cor == "2" ~ "Mulher branca",
    sexo == "2" & raca_cor == "8" ~ "Mulher parda",
    TRUE ~ NA_character_
  )) %>%
  dplyr::filter(!is.na(grupo))

# Mediana por grupo
df_intersec %>%
  group_by(grupo) %>%
  summarise(mediana = median(valor_remuneracao_media),
            n = n()) %>%
  arrange(desc(mediana)) %>%
  print()

# Gráfico interseccionalidade
df_intersec %>%
  group_by(grupo) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = reorder(grupo, mediana), y = mediana, fill = mediana)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))),
            hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Mediana salarial por grupo — interseccionalidade",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "R$") +
  tema_dissertacao +
  theme(legend.position = "none")
ggsave("~/mestrado_parques/graficos/g34_interseccionalidade.png",
       width = 9, height = 6, dpi = 300)

# ANOVA interseccionalidade
modelo_intersec <- aov(valor_remuneracao_media ~ grupo, data = df_intersec)

# Tukey interseccionalidade
tukey_intersec <- TukeyHSD(modelo_intersec)

# Salvar todos os resultados
sink("~/mestrado_parques/outputs/resultados_estatisticos.txt", append = TRUE)
cat("\n=== DECOMPOSIÇÃO OAXACA-BLINDER — BRANCO vs PARDO ===\n\n")
print(summary(resultado_oaxaca))
cat("\n=== ANOVA — INTERSECCIONALIDADE (GÊNERO × RAÇA) ===\n\n")
print(summary(modelo_intersec))
cat("\n=== TUKEY — INTERSECCIONALIDADE PAR A PAR ===\n\n")
print(tukey_intersec)
sink()

cat("\n✅ Seção 13 concluída — Oaxaca-Blinder e interseccionalidade!\n")
