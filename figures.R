################################################################################
# R-Script for Figures
# Author: Christoph Janietz, University of Groningen
# Project: Occupations and Careers within Organizations
# Date: 17-03-2024
################################################################################

library(haven)
library(ggplot2)
library(readxl)
library(tidyverse)
library(scales)
library(survival)
library(survminer)

# Color palettes
kandinsky <- c("#3b7c70", "#898e9f", "#ce9642", "#3b3a3e")
kandinsky2 <- c("#3b7c70", "#ce9642")
kandinsky_kmp <- c("#3b7c70", "#3b7c70", "#898e9f", "#898e9f", "#ce9642", "#ce9642")
kandinsky_cat <- c("#3b7c70", "#ce9642", "#3b7c70", "#ce9642", "#3b7c70", "#ce9642")
kandinsky_oesch <- c("#3b7c70", "#3b7c70", "#3b7c70", "#ce9642", "#ce9642", "#ce9642")
kandinsky_var <- c("#3b3a3e", "#ce9642", "#3b7c70")
gradient <- c("#ffff99", "#a1dab4", "#41b6c4", "#2c7fb8", "#253494")

black <- c("#000000", "#000000", "#000000", "#000000", "#000000", "#000000")
greyscale <- c("#000000", "#2B2A2B", "#555456", "#807F82", "#AAA9AD", "#D5D3D8")
greyscale_cat <- c("#555456", "#D5D3D8", "#555456", "#D5D3D8", "#555456", "#D5D3D8")
greyscale_oesch <- c("#555456", "#555456", "#555456", "#D5D3D8", "#D5D3D8", "#D5D3D8")


##################################################
# Figure 1 - Survival rates by occupational class
##################################################

tte <- read_dta("H:/Christoph/art4/02_posted/time_to_exit.dta")

fit <- survfit(Surv(time, event) ~ cat, data = tte, weights = svyw)

ggsurvplot(fit, data = tte,
           fun = "pct",
           size = 1,
           linetype = "strata",
           legend = "bottom",
           palette = kandinsky_cat,
           censor = FALSE,
           legend.title = "",
           legend.labs = c("Technical (semi-)professionals", "Production workers",
                           "(Associate) managers", "Office workers", 
                           "Socio-cultural (semi-)professionals", "Service workers"))

ggsave("FIG1_survival_rates.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggsurvplot(fit, data = tte,
           fun = "pct",
           size = 1,
           linetype = "strata",
           legend = "bottom",
           palette = greyscale,
           censor = FALSE,
           legend.title = "",
           legend.labs = c("Technical (semi-)professionals", "Production workers",
                           "(Associate) managers", "Office workers", 
                           "Socio-cultural (semi-)professionals", "Service workers"))

ggsave("FIG1BW_survival_rates.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)


###########################################################
# Figure 2 - Relative wage position over 6 years
###########################################################

density <- read_dta("H:/Christoph/art4/02_posted/descriptives_density.dta")

density$oesch.f <- factor(density$oesch, labels = c("Technical (semi-)professionals", 
                                                    "(Associate) managers", 
                                                    "Socio-cultural (semi-)professionals", 
                                                    "Production workers", 
                                                    "Office workers", 
                                                    "Service workers"))

density$counter.f <- factor(density$counter, labels = c("Year of Survey", "6 Years Later"))

ggplot(density, aes(fill=counter.f, linetype=counter.f, weights=svyw)) +
  geom_vline(xintercept=0) +
  geom_density(aes(x=log_real_hwage_ORG), alpha=0.7) +
  scale_x_continuous(limits = c(-2,2)) +
  facet_wrap(~oesch.f) +
  scale_fill_manual(values = kandinsky2) +
  scale_linetype_manual(values = c(2, 1)) +
  labs(x = "Relative wage (within organization)",  
       y = "Density",
       color = "", fill = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("FIG2_density_charts.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(density, aes(fill=counter.f, linetype=counter.f, weights=svyw)) +
  geom_vline(xintercept=0) +
  geom_density(aes(x=log_real_hwage_ORG), alpha=0.7) +
  scale_x_continuous(limits = c(-2,2)) +
  facet_wrap(~oesch.f) +
  scale_fill_grey() +
  scale_linetype_manual(values = c(2, 1)) +
  labs(x = "Relative wage (within organization)",  
       y = "Density",
       color = "", fill = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("FIG2BW_density_charts.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)


###########################################################
# Figure 3 - Fixed Effect Growth Curve Model  
###########################################################

growth <- read_dta("H:/Christoph/art4/02_posted/growth.dta")

growth$oesch.f <- factor(growth$oesch, labels = c("Technical (semi-)professionals", 
                                                  "(Associate) managers", 
                                                  "Socio-cultural (semi-)professionals", 
                                                  "Production workers", 
                                                  "Office workers", 
                                                  "Service workers"))

growth$cat.f <- factor(growth$cat, labels = c("Technical (semi-)professionals",
                                              "Production workers",
                                              "(Associate) managers",
                                              "Office workers",
                                              "Socio-cultural (semi-)professionals", 
                                              "Service workers"))

growth$outcome.f <- factor(growth$outcome, labels = c("Log real hourly wage", 
                                                  "Log real hourly wage + bonus", 
                                                  "Relative wage position (within organization)", 
                                                  "Relative wage position (overall labor market)"))

# Use estimates with demographic controls
growth_dg <- filter(growth, model == "Demographics")

# Limit to real hourly wages
growth_dg_wages <- filter(growth_dg, outcome == 1 | outcome==2)

ggplot(growth_dg_wages, aes(y = growth, x = counter)) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=cat.f), alpha=.4, linetype=0, size=2) +
  geom_line(aes(colour=cat.f), size = 0.5) +
  geom_point(aes(shape=cat.f), size = 2) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_fill_manual(values = kandinsky_cat) +
  scale_colour_manual(values = kandinsky_cat) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2)) +
  facet_wrap(~outcome.f) +
  labs(x = "t",  y = "Growth", 
       color = "", fill = "", shape = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("FIG3_growth_fe.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(growth_dg_wages, aes(y = growth, x = counter)) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=cat.f), alpha=.4, linetype=0, size=2) +
  geom_line(aes(colour=cat.f), size = 0.5) +
  geom_point(aes(shape=cat.f), size = 2) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_fill_manual(values = greyscale_cat) +
  scale_colour_manual(values = greyscale_cat) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2)) +
  facet_wrap(~outcome.f) +
  labs(x = "t",  y = "Growth", 
       color = "", fill = "", shape = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("FIG3BW_growth_fe.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

################################################################
# Figure 4 - Mediation Analysis (Between Class Growth Variance)
################################################################

var_analysis <- read_dta("H:/Christoph/art4/02_posted/var_analysis.dta")

var_analysis <- filter(var_analysis, counter != 0)

var_wages_mediator <- filter(var_analysis, (model == "Firm Quality") &
                                y == "log_real_hwage")
var_wages_baseline <- filter(var_analysis, model == "Demographics" & 
                               y == "log_real_hwage")
var_bonus_mediator <- filter(var_analysis, (model == "Firm Quality") &
                                y == "log_real_hwage_bonus")
var_bonus_baseline <- filter(var_analysis, model == "Demographics" & 
                               y == "log_real_hwage_bonus")

c <- ggplot(var_wages_mediator, aes(y = var_std, x = counter)) +
  geom_line(data = var_wages_baseline, colour="#3b3a3e", size = 1) +
  geom_point(data = var_wages_baseline, colour="#3b3a3e", shape=16, size = 3) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(aes(colour=model), linetype="dashed", size = 0.5) +
  geom_point(aes(colour=model, shape=model), size = 2) +
  geom_text(aes(label=percent(expl,accuracy = 0.1)), size=3, vjust=2, hjust=0.2) +
  scale_x_continuous(breaks = seq(1,6,1), limits = c(1,6.3)) +
  scale_y_continuous(breaks = seq(0,20,2), limits = c(0,20)) +
  scale_fill_manual(values = kandinsky2) +
  scale_colour_manual(values = kandinsky2) +
  scale_shape_manual(values = c(15, 17)) +
  labs(x = "t",  y = "Between-occupation variance \nin wage growth (within organization)", 
       color = "Mediator", shape = "Mediator") +
  theme_minimal() +
  theme(legend.position="bottom")

d <- ggplot(var_bonus_mediator, aes(y = var_std, x = counter)) +
  geom_line(data = var_bonus_baseline, colour="#3b3a3e", size = 1) +
  geom_point(data = var_bonus_baseline, colour="#3b3a3e", shape=16, size = 3) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(aes(colour=model), linetype="dashed", size = 0.5) +
  geom_point(aes(colour=model, shape=model), size = 2) +
  geom_text(aes(label=percent(expl,accuracy = 0.1)), size=3, vjust=2, hjust=0.2) +
  scale_x_continuous(breaks = seq(1,6,1), limits = c(1,6.3)) +
  scale_y_continuous(breaks = seq(0,20,2), limits = c(0,20)) +
  scale_fill_manual(values = kandinsky2) +
  scale_colour_manual(values = kandinsky2) +
  scale_shape_manual(values = c(15, 17)) +
  labs(x = "t",  y = "Between-occupation variance \nin wage growth (within organization)", 
       color = "Mediator", shape = "Mediator") +
  theme_minimal() +
  theme(legend.position="bottom")

figure_mediator <- ggarrange(c, d,
                            legend = c("bottom"),
                            labels = c("Log real hourly wage", "Log real hourly wage (+bonus)"),
                            font.label = list(size = 10),
                            common.legend = TRUE,
                            ncol = 2, nrow = 1)
figure_mediator

ggsave("FIG4_mediation_firm_combined.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

e <- ggplot(var_wages_mediator, aes(y = var_std, x = counter)) +
  geom_line(data = var_wages_baseline, colour="#3b3a3e", size = 1) +
  geom_point(data = var_wages_baseline, colour="#3b3a3e", shape=16, size = 3) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(aes(colour=model), linetype="dashed", size = 0.5) +
  geom_point(aes(colour=model, shape=model), size = 2) +
  geom_text(aes(label=percent(expl,accuracy = 0.1)), size=3, vjust=2, hjust=0.2) +
  scale_x_continuous(breaks = seq(1,6,1), limits = c(1,6.3)) +
  scale_y_continuous(breaks = seq(0,20,2), limits = c(0,20)) +
  scale_fill_grey() +
  scale_colour_grey() +
  scale_shape_manual(values = c(15, 17)) +
  labs(x = "t",  y = "Between-occupation variance \nin wage growth (within organization)", 
       color = "Mediator", shape = "Mediator") +
  theme_minimal() +
  theme(legend.position="bottom")

f <- ggplot(var_bonus_mediator, aes(y = var_std, x = counter)) +
  geom_line(data = var_bonus_baseline, colour="#3b3a3e", size = 1) +
  geom_point(data = var_bonus_baseline, colour="#3b3a3e", shape=16, size = 3) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(aes(colour=model), linetype="dashed", size = 0.5) +
  geom_point(aes(colour=model, shape=model), size = 2) +
  geom_text(aes(label=percent(expl,accuracy = 0.1)), size=3, vjust=2, hjust=0.2) +
  scale_x_continuous(breaks = seq(1,6,1), limits = c(1,6.3)) +
  scale_y_continuous(breaks = seq(0,20,2), limits = c(0,20)) +
  scale_fill_grey() +
  scale_colour_grey() +
  scale_shape_manual(values = c(15, 17)) +
  labs(x = "t",  y = "Between-occupation variance \nin wage growth (within organization)", 
       color = "Mediator", shape = "Mediator") +
  theme_minimal() +
  theme(legend.position="bottom")

figure_mediatorBW <- ggarrange(e, f,
                               legend = c("bottom"),
                               labels = c("Log real hourly wage", "Log real hourly wage (+bonus)"),
                               font.label = list(size = 10),
                               common.legend = TRUE,
                               ncol = 2, nrow = 1)
figure_mediatorBW

ggsave("FIG4BW_mediation_firm_combined.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

####################################################################
# Figure 5 - Fixed Effect Growth Curve Model (Detailed Occupations) 
####################################################################

growth_occdetail <- read_dta("H:/Christoph/art4/02_posted/growth_occdetail.dta")

growth_occdetail <- filter(growth_occdetail, outcome == 1)

growth_occdetail$oesch.f <- factor(growth_occdetail$oesch, labels = c("Technical (semi-)professionals", 
                                                  "(Associate) managers", 
                                                  "Socio-cultural (semi-)professionals", 
                                                  "Production workers", 
                                                  "Office workers", 
                                                  "Service workers"))

#Including detailed growth curves
ggplot(growth_dg_wages, aes(y = growth, x = counter)) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(data=growth_occdetail, aes(group=isco3), colour = "grey", size = 0.4, alpha=.5) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=oesch.f), alpha=.4, linetype=0, size=2) +
  geom_line(aes(colour=oesch.f), size = 0.5) +
  geom_point(aes(shape=oesch.f), size = 2) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_y_continuous(breaks = seq(0,0.2,0.05), limits = c(-0.05,0.2)) +
  scale_fill_manual(values = kandinsky_oesch) +
  scale_colour_manual(values = kandinsky_oesch) +
  scale_shape_manual(values = c(16, 15, 17, 1, 0, 2)) +
  facet_wrap(~oesch.f) +
  labs(x = "t",  y = "Growth", 
       color = "", fill = "", shape = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="none",
        strip.text.x = element_text(size = 8))

ggsave("FIG5_growth_fe_wages_detocc.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(growth_dg_wages, aes(y = growth, x = counter)) +
  geom_hline(yintercept=0, size=0.5) +
  geom_line(data=growth_occdetail, aes(group=isco3), colour = "grey", size = 0.4, alpha=.5) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=oesch.f), alpha=.4, linetype=0, size=2) +
  geom_line(aes(colour=oesch.f), size = 0.5) +
  geom_point(aes(shape=oesch.f), size = 2) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_y_continuous(breaks = seq(0,0.2,0.05), limits = c(-0.05,0.2)) +
  scale_fill_manual(values = black) +
  scale_colour_manual(values = black) +
  scale_shape_manual(values = c(16, 15, 17, 1, 0, 2)) +
  facet_wrap(~oesch.f) +
  labs(x = "t",  y = "Growth", 
       color = "", fill = "", shape = "", linetype = "") +
  theme_minimal() +
  theme(legend.position="none",
        strip.text.x = element_text(size = 8))

ggsave("FIG5BW_growth_fe_wages_detocc.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

################################################################
# Figure 6 - Restricted Vs. Unrestricted Wage Growth
################################################################

growth_unrest <- read_dta("H:/Christoph/art4/02_posted/growth_unrestricted.dta")

growth_unrest$oesch.f <- factor(growth_unrest$oesch, labels = c("Technical (semi-)professionals", 
                                                          "(Associate) managers", 
                                                          "Socio-cultural (semi-)professionals", 
                                                          "Production workers", 
                                                          "Office workers", 
                                                          "Service workers"))

growth_unrest$cat.f <- factor(growth_unrest$cat, labels = c("Technical (semi-)professionals",
                                                      "Production workers",
                                                      "(Associate) managers",
                                                      "Office workers",
                                                      "Socio-cultural (semi-)professionals", 
                                                      "Service workers"))

growth_unrest$outcome.f <- factor(growth_unrest$outcome, labels = c("Log real hourly wage", 
                                                              "Log real hourly wage + bonus"))

# Filter to wages with demographic controls
growth_unrest <- filter(growth_unrest, model == "Demographics" & outcome == 1)

# Append files
growth_combi <- growth_unrest %>%
  bind_rows(growth_dg_wages)

ggplot(growth_unrest, aes(y = growth, x = counter)) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=cat.f), alpha=.4, size=2) +
  geom_line(aes(colour=cat.f, linetype=Growth), size = 0.5) +
  geom_point(aes(shape = cat.f), size = 2) +
  geom_line(data=growth_dg_wages, aes(linetype=Growth), size = 0.5, color="black") +
  geom_point(data=growth_dg_wages, aes(shape = cat.f), size = 2) +
  scale_y_continuous(limits = c(0,0.14), breaks = seq(0,0.14,0.02)) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_fill_manual(values = kandinsky_cat, guide="none") +
  scale_colour_manual(values = kandinsky_cat, guide="none") +
  facet_wrap(~oesch.f) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2), guide="none") +
  scale_linetype_manual(values = c(1, 3)) +
  labs(x = "t",  y = "Growth") +
  theme_minimal() +
  theme(legend.position="bottom", legend.title = element_blank(),
        strip.text.x = element_text(size = 8))

ggsave("FIG6_growth_fe_wages_unrestricted.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(growth_unrest, aes(y = growth, x = counter)) +
  geom_ribbon(aes(ymin = lb, ymax = ub, fill=cat.f), alpha=.4, size=2) +
  geom_line(aes(colour=cat.f, linetype=Growth), size = 0.5) +
  geom_point(aes(shape = cat.f), size = 2) +
  geom_line(data=growth_dg_wages, aes(linetype=Growth), size = 0.5, color="black") +
  geom_point(data=growth_dg_wages, aes(shape = cat.f), size = 2) +
  scale_y_continuous(limits = c(0,0.14), breaks = seq(0,0.14,0.02)) +
  scale_x_continuous(breaks = seq(0,6,1)) +
  scale_fill_manual(values = black, guide="none") +
  scale_colour_manual(values = black, guide="none") +
  facet_wrap(~oesch.f) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2), guide="none") +
  scale_linetype_manual(values = c(1, 3)) +
  labs(x = "t",  y = "Growth") +
  theme_minimal() +
  theme(legend.position="bottom", legend.title = element_blank(),
        strip.text.x = element_text(size = 8))

ggsave("FIG6BW_growth_fe_wages_unrestricted.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

################################################################
# Supplementary material
################################################################

################################################################
# Analysis of firm fixed effects
################################################################

j_fe_detail <- read_dta("H:/Christoph/art4/02_posted/j_fe_detail.dta")

j_fe_detail$sample.f <- factor(j_fe_detail$sample, labels = c("Not in sample", 
                                                              "In sample"))
j_fe_detail$firmqual.f <- factor(j_fe_detail$firmqual, labels = c("Very low-paying", 
                                                                  "Low-paying", 
                                                                  "Average-paying", 
                                                                  "High-paying", 
                                                                  "Very high-paying"))

ggplot(j_fe_detail, aes(linetype=sample.f, fill=sample.f)) +
  geom_vline(xintercept=0) +
  geom_density(aes(x=j_fe), alpha=0.7) +
  scale_x_continuous(limits = c(-1,1)) +
  scale_linetype_manual(values = c(2, 1)) +
  scale_fill_manual(values = kandinsky2) +
  labs(x = "Organization fixed effect (as estimated by AKM model)",  
       y = "Density",
       linetype = "", fill = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("SUPP_j_fe_sample.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(j_fe_detail, aes(fill=firmqual.f)) +
  geom_vline(xintercept=0) +
  geom_density(aes(x=j_fe), alpha=1) +
  geom_hline(yintercept=0) +
  scale_x_continuous(limits = c(-1,1)) +
  scale_color_manual(values = gradient) +
  scale_fill_manual(values = gradient) +
  labs(x = "Organization fixed effect (as estimated by AKM model)",  
       y = "Density", fill = "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("SUPP_j_fe_distribution.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

#####################################################################
# Correlation Baseline Wages & Growth (Occupations)
#####################################################################

corr_occ <- read_dta("H:/Christoph/art4/02_posted/corr_occ.dta")

corr_occ$cat.f <- factor(corr_occ$cat, labels = c("Technical (semi-)professionals",
                                              "Production workers",
                                              "(Associate) managers",
                                              "Office workers",
                                              "Socio-cultural (semi-)professionals", 
                                              "Service workers"))

ggplot(corr_occ, aes(y = growth, x = hw, size=N, weight=N)) +
  geom_hline(yintercept=0) +
  geom_smooth(method = "loess", formula = "y~x", se=TRUE, span=5, color='black') +
  geom_point(aes(fill=cat.f, shape=cat.f, color=cat.f)) + 
  scale_colour_manual(values = kandinsky_cat) +
  scale_x_continuous(limits = c(9,45), breaks = seq(10,50,10),
                     labels = label_number(accuracy = 0.01, suffix = "€")) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2)) +
  scale_size(guide = 'none') +
  labs(x = "Average real hourly wage at t=0",  
       y = "Predicted wage growth rate at t=6", 
       color = "", fill = "", shape = "", linetype = "", size= "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("SUPP_corr_occ_hw.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)

ggplot(corr_occ, aes(y = growth, x = relpos_org, size=N, weight=N)) +
  geom_hline(yintercept=0) +
  geom_vline(xintercept=0) +
  geom_smooth(method = "loess", formula = "y~x", se=TRUE, span=5, color='black') +
  geom_point(aes(fill=cat.f, shape=cat.f, color=cat.f)) + 
  scale_colour_manual(values = kandinsky_cat) +
  scale_x_continuous(limits = c(-1,2), breaks = seq(-1,2,1)) +
  scale_shape_manual(values = c(16, 1, 15, 0, 17, 2)) +
  scale_size(guide = 'none') +
  labs(x = "Average relative wage position (within organization) at t=0",
       y = "Predicted wage growth rate at t=6", 
       color = "", fill = "", shape = "", linetype = "", size= "") +
  theme_minimal() +
  theme(legend.position="bottom",
        strip.text.x = element_text(size = 8))

ggsave("SUPP_corr_occ_relorg.pdf", path = "H:/Christoph/art4/05_figures", useDingbats = FALSE)
