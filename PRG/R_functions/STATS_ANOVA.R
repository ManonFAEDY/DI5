## STATS_ANOVA
##
## Calling Sequence
##  STATS_ANOVA = function(dataframe, Variable_name)
##
## Authors
##  Manon Faedy - Univ Montpellier - France
## 
## Versions
##  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
## 
## Description
##  STATS_ANOVA is a file containing a function to realize descriptives statistics,
## ANOVA, post-hoc tests, complementary test, plots, and save

################################################################################
################################################################################
#### FIRST : Initialize ####

#load packages
library(car)
library(carData)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggpubr)
library(glue)
library(graphics)
library(naniar)
library(rlang)
library(rstatix)
library(stats)
library(tidyr)
library(tidyverse)
library(tibble)
library(utils)
library(mbir)
################################################################################
################################################################################
#### SECOND : function ####
STATS_ANOVA = function(dataframe, Variable_name) {
  ####STEP 1 : Descriptive stats ####
  sum = dataframe %>%
    group_by(Moment,Groupe) %>%
    get_summary_stats(Variable, type = "mean_sd")
  
  ################################################################################
  ####STEP 2 : Pre-anova tests ####
  #Equality of variance (Levene test)
  lev = dataframe %>%
    group_by(Moment) %>%
    levene_test(Variable~Groupe)
  
  #Normality assumption (Shapiro-Wilk test)
  nrm = dataframe %>%
    group_by(Moment,Groupe) %>%
    shapiro_test(Variable)
  
  ################################################################################
  ####STEP 3 : Anova ####
  res.aov = anova_test(data = dataframe
                        , formula = Variable ~ Moment * Groupe
                        , wid = Sujet
                        , type = 3              #cause unbalanced data
                        , white.adjust = TRUE   #heteroscedasticity correct
                        , detailed = TRUE
  )

  ################################################################################
  ####STEP 4 : Post-Hoc ####
  
  if (nrm[,5] > 0.05) #parametric comparisons
  {
      #Pairwise comparisons between treatment groups
      pwc = dataframe %>%
        group_by(Moment) %>%
        pairwise_t_test(
          formula = Variable ~ Groupe
          , paired = FALSE
          , p.adjust.method = "bonferroni"
        )
      
      #Pairwise comparisons between time points
      pwc2 = dataframe %>%
        group_by(Groupe) %>%
        pairwise_t_test(
          formula = Variable ~ Moment
          , paired = TRUE
          , p.adjust.method = "bonferroni"
        )
  }
  
  else #non parametric comparisons
  {
      #Pairwise comparisons between treatment groups
      pwc = dataframe %>%
        group_by(Moment) %>%
        pairwise.wilcox.test(
          x = Variable
          , g = Groupe
          , paired = FALSE
          , p.adjust.method = "bonferroni"
        )
      
      #Pairwise comparisons between time points
      pwc2 = dataframe %>%
        group_by(Groupe) %>%
        pairwise.wilcox.test(
          x = Variable
          , g = Groupe
          , paired = TRUE
          , p.adjust.method = "bonferroni"
        )
  }
  
  ################################################################################
  ####STEP 5 : Size effect (Cohen's d) ####
  #Pairwise comparisons between treatment groups
  d_Moment = dataframe %>%
    group_by(Moment) %>%
    cohens_d(
      formula = Variable ~ Groupe,
    )
  
  #Pairwise comparisons between time points
  d_Groupe = dataframe %>%
    group_by(Groupe) %>%
    cohens_d(
      formula = Variable ~ Moment,
    )
  
  ################################################################################
  ####STEP 6 : Box plots with p-values ####
  pwc = pwc %>%
    add_xy_position(x = "Moment")  
  
  pwc2 = pwc2 %>%
    add_xy_position(x = "Groupe")
  
  pwc2$y.position = pwc$y.position - pwc$y.position*0.10
  pwc2$xmin = c(pwc$xmin[1],pwc$xmax[1])
  pwc2$xmax = c(pwc$xmin[2],pwc$xmax[2])
  
  bxp = ggboxplot(data = dataframe
                   , x = "Moment"
                   , y = "Variable"
                   , color = "Groupe"
                   , palette = "aaas"
                   , title = paste0("Boxplot of ",Variable_name," \n by Moment")
                   , xlab = "Moment"
                   , ylab = Variable_name
                   , short.panel.labs = FALSE
                   , add = "jitter") + 
    stat_pvalue_manual(pwc
                       , label = "p = {p}"
                       , y.position = "y.position"
                       , tip.length = 0.03
                       , hide.ns = FALSE) + 
    stat_pvalue_manual(pwc2
                       , label = "p = {p}"
                       , y.position = "y.position"
                       , tip.length = 0.03
                       , hide.ns = FALSE) +
    labs(subtitle = get_test_label(res.aov
                                   , detailed = TRUE),
     caption = get_pwc_label(pwc)
    )
  print(bxp)

  ################################################################################
  ####STEP 7 : Output ####
  STATS_ANOVA = list("Summary" = sum
                     ,"Levene" = lev
                     , "ChapiroWilk" = nrm
                     , "ANOVA" = res.aov
                     , "PostHocGoupe" = pwc
                     , "PostHocMoment" = pwc2
                     , "CohenMoment" = d_Moment
                     , "CohenGroupe" = d_Groupe
                     , "BoxplotGoupe" = bxp)
  ################################################################################
}
