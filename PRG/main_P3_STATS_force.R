## P3_STATS_force
##
## Calling Sequence
##  none : P3_STATS_force is the entry point 
##
## Authors
##  Manon Faedy - Univ Montpellier - France
## 
## Versions
##  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
## 
## Description
##  P_STATS_force is the file to run using the Rstudio interface 
##  The script always contains two parts : 
##  1°) set up of working environement 
##  2°) computations (in the right setup) :
##     Statistics and plots of data

################################################################################
################################################################################
#### FIRST : Initialize ####
#clear the workspace
rm(list = ls())

#code the directory structure relative to the present file
PRG_PATH = dirname(rstudioapi::getSourceEditorContext()$path) # get absolute file path of P_STATS_force.R
setwd(dirname(PRG_PATH))                                      # get absolute file path of PRG_PATH as new working directory
WRK_PATH = getwd()                                            # store the present directory
DAT_PATH = file.path(WRK_PATH,"DAT")                          # DAT, that is within WRK
RES_PATH = file.path(WRK_PATH,"RES")                          # RES, that is within WRK
RES_SCILAB_PATH = file.path(RES_PATH,"RES_SCILAB")            # RES_SCILAB, that is within RES
RES_R_PATH = file.path(RES_PATH,"RES_R")                      # RES_R, that is within RES
RES_R_PLOTS_PATH = file.path(RES_R_PATH,"Plots_R")            # RES_R_PLOTS, that is within RES_R
PRG_R_FUNCTION_PATH = file.path(PRG_PATH,"R_functions")       # PRG_R_FUNCTION_PATH, that is within PRG

#load packages
library(dplyr)
library(forcats)
library(grDevices)
library(naniar)
library(rlang)
library(rstatix)
library(stats)
library(tibble)
library(tidyverse)
library(utils)
################################################################################
################################################################################
#### SECOND : Sorting and correction of data, statistics, plots ####
####STEP 1 : Define conditions to work on (Body_Part, Movement) & load data ####
Body_Part = NaN
Movement = NaN

##Ask user to choose the wanted condition 
while (Body_Part != "Cheville" && Body_Part != "Genou")
{Body_Part = readline(prompt = "Do you want to work on 'Cheville' or 'Genou' data : ")
}

while (Movement != "Flex" && Movement != "Ext")
{Movement = readline(prompt = "Do you want to work on 'Flex' or 'Ext' data : ")
}

##Load data
FileName_Data = paste0("Tableau_recap_MVC_",Body_Part,"_",Movement,"_Resultats.csv", sep = "")
FullFileName_Data = file.path(RES_SCILAB_PATH, FileName_Data)
Data = read.delim(FullFileName_Data, stringsAsFactors=TRUE)

##Recap the chosen conditions
print(paste0("You choosed to work on the body part : ", Body_Part))
print(paste0("You choosed to work on the movement : ", Movement))
print(paste0("The corresponding file for the analysis is ", FileName_Data))

################################################################################
####STEP 2 : Group data and delete unused ones ####
#if R2 value is under 0.90, delete row
Data_filt = Data[!(Data$R2 <= 0.90),]
Suppr = nrow(Data) - nrow(Data_filt)
Message1 = paste0("Le nombre de lignes supprimées car R2 < 0.90 est de ",Suppr," sur ",nrow(Data))
print(Message1)

##group data by Subject and Moment, and extract usefull data (k1, kACT)
SUM = aggregate(Data_filt, by = list(Data_filt$Subject,Data_filt$Moment), FUN = mean)
colnames(SUM)[1] = "Sujet"
colnames(SUM)[2] = "Moment"
Data_filt_sum = SUM[,c("Sujet", "Moment", "k1", "kACT")]

##make a summary of Data_filt_sum to see if some subjects have data only in pre or post
SUM_subjects = Data_filt_sum %>%
  group_by(Sujet) %>%
  summarise(no_rows = length(Sujet))

##delete subject's data if has data only in pre or post
Data_filt_sum_filt = Data_filt_sum
for (s in 1:nrow(SUM_subjects)) {
  if(SUM_subjects$no_rows[s] == 1)
  {Todel = as.character(SUM_subjects$Sujet[s])
  print(paste0("Subjet ",Todel," has missing data, he is excluded from study."))
  Data_filt_sum_filt = Data_filt_sum_filt[!(Data_filt_sum_filt$Sujet == Todel), ]
  }
}
################################################################################
####STEP 3 : Add group factor and separate variable ####
##load "Repartition_groupes.txt" with the distributions of subjects data
FullFileNameRep_grp = file.path(DAT_PATH, "Repartition_groupes.txt")
Rep_grp = read.delim2(FullFileNameRep_grp)

##deleted rows with subjects which are not in the data
for (g in 1:nrow(Rep_grp)) {
  if(Rep_grp$Sujet[g] %in% Data_filt_sum_filt$Sujet == FALSE)
  {print(paste0("Subjet ",Rep_grp$Sujet[g]," is missing."))
    Rep_grp[g,] = NA
  }
}
Rep_grp = Rep_grp[complete.cases(Rep_grp), ]

#add column 'Groupe' to Data_filt_sum_filt
Groupe = as.character(Rep_grp$Groupe)
Data_filt_sum_filt = add_column(Data_filt_sum_filt
                                      ,Groupe = as.factor(c(Groupe, Groupe))
                                      ,.after = "Sujet")

#save dataframe to use in jamovi
FileName_Tableau = paste0("Sum_",Body_Part,"_",Movement,".csv")
FullFileName_Tableau = file.path(RES_R_PATH,FileName_Tableau)
write.table(Data_filt_sum_filt
            , file = FullFileName_Tableau
            , sep="\t"
            , col.names=T
            , row.names=F
            , quote=F)

#make a dataframe for each variable
#...to be used in "STATS_ANOVA.R" function
Data_k1 = Data_filt_sum_filt[,-5]
Data_kACT = Data_filt_sum_filt[,-4]

#rename as "Variable" the column 4 of Data_k1 and Data_kACT
#...to be used in "STATS_ANOVA.R" function
colnames(Data_k1)[4] = "Variable"
colnames(Data_kACT)[4] = "Variable"

################################################################################
####STEP 4 : Statistics and save plots & results ####
#execute the operator function "STATS_ANOVA.R"
FileName_Function = "STATS_ANOVA.R"
FullFileName_Function = file.path(PRG_R_FUNCTION_PATH, FileName_Function)
source(file = FullFileName_Function)

#open a pdf file where plots will be saved
FileNamePlotPDF = paste0("Plot_Stats_k1_kACT_",Body_Part,"_",Movement,".pdf")
FullFileNamePlotPDF = file.path(RES_R_PLOTS_PATH,FileNamePlotPDF)
pdf(file = FullFileNamePlotPDF
    , onefile = TRUE
    , paper = "a4"
    , bg = "white")

k1_results = STATS_ANOVA(Data_k1, "k1")
kACT_results = STATS_ANOVA(Data_kACT, "kACT")

#close pdf file
dev.off()

#print results in console
name_res_k1 = "ANALYSES STATISTIQUES POUR LA VARIABLE K1"
print(name_res_k1)
print(k1_results)

name_res_kACT = "ANALYSES STATISTIQUES POUR LA VARIABLE KACT"
print(name_res_kACT)
print(kACT_results)

#save results in txt file in RES_R_PATH
FileNameRes = paste0("Stats_k1_kACT_",Body_Part,"_",Movement,".txt")
FullFileNameRes = file.path(RES_R_PATH,FileNameRes)
capture.output(c(name_res_k1, k1_results,name_res_kACT,kACT_results)
               , file = FullFileNameRes)

################################################################################
