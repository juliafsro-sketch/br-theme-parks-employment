# ================================================
# MESTRADO - Mercado de Trabalho em Parques Temáticos
# Script 02 - Gráficos Finais Padronizados
# Tema: Clean acadêmico — paleta plasma (viridis)
# ================================================

library(tidyverse)
library(basedosdados)
library(geobr)
library(patchwork)
library(viridis)

# ------------------------------------------------
# CARREGAR DADOS
# ------------------------------------------------
df       <- readRDS("~/mestrado_parques/dados/brutos/rais_parques_2020_2024.rds")
df_caged <- readRDS("~/mestrado_parques/dados/brutos/caged_parques_2020_2024.rds")

municipios <- read_municipality(year = 2020, showProgress = FALSE) %>%
  as.data.frame() %>%
  select(code_muni, name_muni) %>%
  mutate(id_municipio = as.character(code_muni))

# ------------------------------------------------
# TEMA PADRÃO
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

# Cores plasma pra positivo/negativo e duas categorias
cor_pos <- "#f89540"   # laranja plasma
cor_neg <- "#7201a8"   # roxo plasma

# ------------------------------------------------
# GRÁFICO 1 — Vínculos por estado
# ------------------------------------------------
g1 <- df %>%
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

ggsave("~/mestrado_parques/graficos/g01_vinculos_por_estado.png", g1,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 2 — Top 20 municípios
# ------------------------------------------------
df_municipios <- df %>%
  group_by(id_municipio, sigla_uf) %>%
  summarise(total_vinculos = n(), .groups = "drop") %>%
  arrange(desc(total_vinculos)) %>%
  left_join(municipios, by = "id_municipio") %>%
  select(name_muni, sigla_uf, total_vinculos)

g2 <- df_municipios %>%
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

ggsave("~/mestrado_parques/graficos/g02_top20_municipios.png", g2,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 3 — Evolução anual
# ------------------------------------------------
g3 <- df %>%
  count(ano) %>%
  ggplot(aes(x = as.numeric(ano), y = n)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = n), vjust = -0.8, size = 3.5) +
  labs(title = "Evolução anual dos vínculos formais",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Total de vínculos") +
  tema_dissertacao

ggsave("~/mestrado_parques/graficos/g03_evolucao_anual.png", g3,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 4 — Vínculos ativos em 31/12
# ------------------------------------------------
g4 <- df %>%
  filter(vinculo_ativo_3112 == "1") %>%
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

ggsave("~/mestrado_parques/graficos/g04_vinculos_ativos_3112.png", g4,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 5 — Municípios com parques ativos
# ------------------------------------------------
g5 <- df %>%
  filter(vinculo_ativo_3112 == "1") %>%
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

ggsave("~/mestrado_parques/graficos/g05_municipios_ativos.png", g5,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 6 — Admissões por mês
# ------------------------------------------------
g6 <- df %>%
  filter(!is.na(mes_admissao), mes_admissao > 0) %>%
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

ggsave("~/mestrado_parques/graficos/g06_admissoes_por_mes.png", g6,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 7 — Sazonalidade por cluster
# ------------------------------------------------
g7 <- df %>%
  filter(!is.na(mes_admissao), mes_admissao > 0) %>%
  filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
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

ggsave("~/mestrado_parques/graficos/g07_sazonalidade_cluster.png", g7,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 8 — Gênero
# ------------------------------------------------
g8 <- df %>%
  filter(!is.na(sexo)) %>%
  mutate(genero = ifelse(sexo == "1", "Masculino", "Feminino")) %>%
  count(genero) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = genero, y = pct, fill = genero)) +
  geom_col() +
  scale_fill_manual(values = c("Feminino" = cor_neg, "Masculino" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Distribuição por gênero",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g08_genero.png", g8,
       width = 7, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 9 — Idade
# ------------------------------------------------
g9 <- df %>%
  filter(!is.na(idade), idade > 0, idade < 80) %>%
  mutate(idade = as.numeric(idade)) %>%
  ggplot(aes(x = idade)) +
  geom_histogram(binwidth = 2, fill = cor_pos, color = "white") +
  labs(title = "Distribuição por idade",
       subtitle = "Brasil, 2020–2024",
       x = "Idade", y = "Total de vínculos") +
  tema_dissertacao

ggsave("~/mestrado_parques/graficos/g09_idade.png", g9,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 10 — Escolaridade
# ------------------------------------------------
g10 <- df %>%
  filter(!is.na(grau_instrucao_apos_2005)) %>%
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
  arrange(desc(n)) %>%
  ggplot(aes(x = reorder(escolaridade, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Escolaridade dos trabalhadores",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g10_escolaridade.png", g10,
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 11 — Raça/cor
# ------------------------------------------------
g11 <- df %>%
  filter(!is.na(raca_cor)) %>%
  mutate(raca = case_when(
    raca_cor == "1" ~ "Indígena",
    raca_cor == "2" ~ "Branca",
    raca_cor == "4" ~ "Preta",
    raca_cor == "6" ~ "Amarela",
    raca_cor == "8" ~ "Parda",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(raca)) %>%
  count(raca) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  arrange(desc(n)) %>%
  ggplot(aes(x = reorder(raca, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Distribuição por raça/cor",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g11_raca_cor.png", g11,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 12 — Remuneração em R$
# ------------------------------------------------
g12 <- df %>%
  filter(!is.na(valor_remuneracao_media), valor_remuneracao_media > 0,
         valor_remuneracao_media < 10000) %>%
  ggplot(aes(x = valor_remuneracao_media)) +
  geom_histogram(binwidth = 200, fill = cor_pos, color = "white") +
  labs(title = "Distribuição da remuneração média",
       subtitle = "Brasil, 2020–2024 (valores até R$10.000)",
       x = "Remuneração média (R$)", y = "Total de vínculos") +
  tema_dissertacao

ggsave("~/mestrado_parques/graficos/g12_remuneracao_rs.png", g12,
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 13 — Remuneração em salários mínimos
# ------------------------------------------------
g13 <- df %>%
  filter(!is.na(valor_remuneracao_media_sm), valor_remuneracao_media_sm > 0) %>%
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
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g13_remuneracao_sm.png", g13,
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 14 — Mediana salarial por cluster
# ------------------------------------------------
g14 <- df %>%
  filter(!is.na(valor_remuneracao_media), valor_remuneracao_media > 0) %>%
  filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
  group_by(sigla_uf) %>%
  summarise(mediana_salario = median(valor_remuneracao_media)) %>%
  arrange(desc(mediana_salario)) %>%
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

ggsave("~/mestrado_parques/graficos/g14_mediana_salarial_cluster.png", g14,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 15 — Tempo de emprego
# ------------------------------------------------
g15 <- df %>%
  filter(!is.na(tempo_emprego), tempo_emprego > 0) %>%
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
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g15_tempo_emprego.png", g15,
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 16 — Trabalho intermitente
# ------------------------------------------------
g16 <- df %>%
  filter(!is.na(indicador_trabalho_intermitente)) %>%
  mutate(intermitente = ifelse(indicador_trabalho_intermitente == "1",
                               "Intermitente", "Regular")) %>%
  count(intermitente) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = intermitente, y = pct, fill = intermitente)) +
  geom_col() +
  scale_fill_manual(values = c("Intermitente" = cor_neg, "Regular" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Trabalho intermitente",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g16_trabalho_intermitente.png", g16,
       width = 7, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 17 — Trabalho parcial
# ------------------------------------------------
g17 <- df %>%
  filter(!is.na(indicador_trabalho_parcial)) %>%
  mutate(parcial = ifelse(indicador_trabalho_parcial == "1",
                          "Parcial", "Regular")) %>%
  count(parcial) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = parcial, y = pct, fill = parcial)) +
  geom_col() +
  scale_fill_manual(values = c("Parcial" = cor_neg, "Regular" = cor_pos)) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Trabalho parcial",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g17_trabalho_parcial.png", g17,
       width = 7, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 18 — Top 15 ocupações
# ------------------------------------------------
g18 <- df %>%
  filter(!is.na(cbo_2002)) %>%
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

ggsave("~/mestrado_parques/graficos/g18_top15_ocupacoes.png", g18,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 19 — Tamanho dos estabelecimentos
# ------------------------------------------------
g19 <- df %>%
  filter(!is.na(tamanho_estabelecimento)) %>%
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
  filter(!is.na(tamanho)) %>%
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

ggsave("~/mestrado_parques/graficos/g19_tamanho_estabelecimento.png", g19,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 20 — Natureza jurídica
# ------------------------------------------------
g20 <- df %>%
  filter(!is.na(natureza_juridica)) %>%
  mutate(natureza = case_when(
    substr(natureza_juridica, 1, 1) == "1" ~ "Administração pública",
    substr(natureza_juridica, 1, 1) == "2" ~ "Entidades empresariais",
    substr(natureza_juridica, 1, 1) == "3" ~ "Entidades sem fins lucrativos",
    substr(natureza_juridica, 1, 1) == "4" ~ "Pessoas físicas",
    TRUE ~ "Outro"
  )) %>%
  count(natureza) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  arrange(desc(n)) %>%
  ggplot(aes(x = reorder(natureza, pct), y = pct, fill = pct)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Natureza jurídica dos estabelecimentos",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "%") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g20_natureza_juridica.png", g20,
       width = 9, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 21 — QL Top 15
# ------------------------------------------------
set_billing_id("mestrado-rais-498203")

query_total <- "
  SELECT id_municipio, ano, COUNT(*) as total_empregos
  FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE ano BETWEEN 2020 AND 2024
  GROUP BY id_municipio, ano
"
df_total <- read_sql(query_total, billing_project_id = "mestrado-rais-498203")

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

g21 <- df_ql %>%
  filter(ano == 2024) %>%
  arrange(desc(ql)) %>%
  slice_head(n = 15) %>%
  left_join(municipios, by = "id_municipio") %>%
  ggplot(aes(x = reorder(name_muni, ql), y = ql, fill = ql)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = round(ql, 0)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Quociente Locacional (QL) — Top 15 municípios",
       subtitle = "Brasil, 2024",
       x = "", y = "QL") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g21_ql_top15.png", g21,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 22 — HHI
# ------------------------------------------------
df_hhi <- df %>%
  group_by(ano, id_municipio) %>%
  summarise(emp_muni = n(), .groups = "drop") %>%
  left_join(df %>% group_by(ano) %>%
              summarise(emp_total = n(), .groups = "drop"), by = "ano") %>%
  mutate(s = emp_muni / emp_total) %>%
  group_by(ano) %>%
  summarise(hhi = sum(s^2))

g22 <- df_hhi %>%
  ggplot(aes(x = as.numeric(ano), y = hhi)) +
  geom_line(linewidth = 1.2, color = cor_pos) +
  geom_point(size = 3, color = cor_pos) +
  geom_text(aes(label = round(hhi, 4)), vjust = -0.8, size = 3.5) +
  labs(title = "Índice HHI — concentração territorial do emprego",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "HHI") +
  tema_dissertacao

ggsave("~/mestrado_parques/graficos/g22_hhi.png", g22,
       width = 8, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 23 — QL x Salário
# ------------------------------------------------
df_ql_salario <- df %>%
  filter(ano == 2024, valor_remuneracao_media > 0,
         !is.na(valor_remuneracao_media)) %>%
  group_by(id_municipio) %>%
  summarise(mediana_salario = median(valor_remuneracao_media),
            total_vinculos = n(), .groups = "drop") %>%
  left_join(df_ql %>% filter(ano == 2024), by = "id_municipio") %>%
  left_join(municipios, by = "id_municipio") %>%
  filter(!is.na(ql), total_vinculos >= 50)

g23 <- ggplot(df_ql_salario, aes(x = ql, y = mediana_salario)) +
  geom_point(aes(size = total_vinculos, color = mediana_salario), alpha = 0.7) +
  scale_color_viridis(option = "plasma", direction = -1) +
  geom_smooth(method = "lm", color = "#440154", se = TRUE) +
  geom_text(data = df_ql_salario %>% filter(ql > 50),
            aes(label = name_muni), vjust = -0.8, size = 3) +
  labs(title = "Especialização (QL) × Remuneração mediana por município",
       subtitle = "Brasil, 2024",
       x = "Quociente Locacional (QL)",
       y = "Mediana salarial (R$)",
       size = "Vínculos") +
  tema_dissertacao +
  theme(legend.position = "right")

ggsave("~/mestrado_parques/graficos/g23_ql_vs_salario.png", g23,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 24 — Desigualdade salarial
# ------------------------------------------------
p_genero <- df %>%
  filter(!is.na(sexo), valor_remuneracao_media > 0) %>%
  mutate(genero = ifelse(sexo == "1", "Masculino", "Feminino")) %>%
  group_by(genero) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = genero, y = mediana, fill = genero)) +
  geom_col() +
  scale_fill_manual(values = c("Feminino" = cor_neg, "Masculino" = cor_pos)) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))), vjust = -0.5, size = 3.5) +
  labs(title = "Por gênero", x = "", y = "R$") +
  tema_dissertacao +
  theme(legend.position = "none")

p_raca <- df %>%
  filter(!is.na(raca_cor), valor_remuneracao_media > 0) %>%
  mutate(raca = case_when(
    raca_cor == "2" ~ "Branca",
    raca_cor == "4" ~ "Preta",
    raca_cor == "8" ~ "Parda",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(raca)) %>%
  group_by(raca) %>%
  summarise(mediana = median(valor_remuneracao_media)) %>%
  ggplot(aes(x = reorder(raca, mediana), y = mediana, fill = mediana)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = paste0("R$", round(mediana, 0))), vjust = -0.5, size = 3.5) +
  labs(title = "Por raça/cor", x = "", y = "R$") +
  tema_dissertacao +
  theme(legend.position = "none")

g24 <- p_genero + p_raca +
  plot_annotation(title = "Desigualdade salarial — parques temáticos no Brasil",
                  subtitle = "Brasil, 2020–2024")

ggsave("~/mestrado_parques/graficos/g24_desigualdade_salarial.png", g24,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 25 — Tempo de emprego por ocupação
# ------------------------------------------------
g25 <- df %>%
  filter(!is.na(tempo_emprego), tempo_emprego > 0) %>%
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
  filter(!is.na(ocupacao)) %>%
  group_by(ocupacao) %>%
  summarise(mediana_meses = median(tempo_emprego)) %>%
  arrange(desc(mediana_meses)) %>%
  ggplot(aes(x = reorder(ocupacao, mediana_meses), y = mediana_meses,
             fill = mediana_meses)) +
  geom_col() +
  scale_fill_viridis(option = "plasma", direction = -1) +
  geom_text(aes(label = round(mediana_meses, 1)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "Tempo mediano de emprego por ocupação",
       subtitle = "Brasil, 2020–2024",
       x = "", y = "Meses") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g25_tempo_emprego_ocupacao.png", g25,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 26 — Escolaridade x Remuneração
# ------------------------------------------------
g26 <- df %>%
  filter(!is.na(grau_instrucao_apos_2005), valor_remuneracao_media > 0) %>%
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
  filter(!is.na(escolaridade)) %>%
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
       subtitle = "Brasil, 2020–2024",
       x = "", y = "R$") +
  tema_dissertacao +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

ggsave("~/mestrado_parques/graficos/g26_escolaridade_vs_salario.png", g26,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 27 — Saldo anual por cluster (CAGED)
# ------------------------------------------------
g27 <- df_caged %>%
  filter(sigla_uf %in% c("SP","SC","RS","CE","PR","GO")) %>%
  group_by(ano, sigla_uf) %>%
  summarise(saldo = sum(saldo_movimentacao), .groups = "drop") %>%
  ggplot(aes(x = as.numeric(ano), y = saldo, fill = saldo > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = cor_pos, "FALSE" = cor_neg)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  facet_wrap(~sigla_uf, scales = "free_y") +
  labs(title = "Saldo anual por cluster — impacto da pandemia e recuperação",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Saldo") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g27_saldo_cluster_caged.png", g27,
       width = 10, height = 7, dpi = 300)

# ------------------------------------------------
# GRÁFICO 28 — Saldo mensal CAGED
# ------------------------------------------------
g28 <- df_caged %>%
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

ggsave("~/mestrado_parques/graficos/g28_saldo_mensal_caged.png", g28,
       width = 10, height = 6, dpi = 300)

# ------------------------------------------------
# GRÁFICO 29 — Saldo anual CAGED
# ------------------------------------------------
saldos <- df_caged %>%
  group_by(ano) %>%
  summarise(saldo_anual = sum(saldo_movimentacao))

g29 <- saldos %>%
  ggplot(aes(x = as.numeric(ano), y = saldo_anual, fill = saldo_anual > 0)) +
  geom_col() +
  geom_text(aes(label = saldo_anual,
                vjust = ifelse(saldo_anual > 0, -0.5, 1.5)),
            size = 3.5) +
  scale_fill_manual(values = c("TRUE" = cor_pos, "FALSE" = cor_neg)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666") +
  labs(title = "Saldo anual de empregos",
       subtitle = "Brasil, 2020–2024",
       x = "Ano", y = "Saldo") +
  tema_dissertacao +
  theme(legend.position = "none")

ggsave("~/mestrado_parques/graficos/g29_saldo_anual_caged.png", g29,
       width = 8, height = 6, dpi = 300)
