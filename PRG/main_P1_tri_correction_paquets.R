## P1_tri_correction_paquets 
##
## Calling Sequence
##  none : P1_tri_correction_paquets is the entry point 
##
## Authors
##  Manon Faedy - Univ Montpellier - France
## 
## Versions
##  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
## 
## Description
##  P1_tri_correction_paquets is the file to run using the Rstudio interface 
##  The script always contains two parts : 
##  1°) set up of working environement 
##  2°) computations (in the right setup) :
##     sorting, correction and organization of files

################################################################################
################################################################################
#### FIRST : Initialize ####
#clear the workspace
rm(list = ls())

#code the directory structure relative to the present file
PRG_PATH = dirname(rstudioapi::getSourceEditorContext()$path) # get absolute file path of P1_tri_correction_paquets .R
setwd(dirname(PRG_PATH))                                      # get absolute file path of PRG_PATH as new working directory
WRK_PATH = getwd()                                            # store the present directory
DAT_PATH = file.path(WRK_PATH,"DAT")                          # DAT, that is within WRK
RES_PATH = file.path(WRK_PATH,"RES")                          # RES, that is within WRK
RES_SCILAB_PATH = file.path(RES_PATH,"RES_SCILAB")            # RES_SCILAB, that is within RES
RES_R_PATH = file.path(RES_PATH,"RES_R")                      # RES_R, that is within RES

#load packages
library(dplyr)
library(rlang)
library(rstatix)
library(utils)

################################################################################
################################################################################
#### SECOND : Correction of identification data, creation of sub-packages ####
####STEP 1 : list the raw files in .CTM format ####
CTMFileList = list.files(DAT_PATH
                         , pattern = ".CTM"
                         , full.names = TRUE)

#create dataframe to compile informations
NbFile = length(CTMFileList)
Variables = c("File_name"
              , "Program"
              , "Date_ddmmyyyy"
              , "Subject"
              , "Moment"
              , "Birth_ddmmyyyy"
              , "Weight_kg"
              , "Height_cm"
              , "Body_Part"
              , "Side"
              , "Movement")
Nb_variables = length(Variables)
Tableau_recap = data.frame(matrix(nrow=NbFile
                                     , ncol=Nb_variables))
colnames(Tableau_recap) = Variables

################################################################################
####STEP 2 : extract important informations ####
##Open a loop to load data file listed in Tableau_recap one after the other
for(i in 1:NbFile){
  #load data
  Data = read.table(file = as.character(CTMFileList[i])
                           , sep=""
                           , dec="."
                           , header=F
                           , na.strings = ""
                           , fill=T
                           , colClasses = "character"
                           , blank.lines.skip=F)

  #listing importante variables with their coordinates
  Program = Data[2,12]
  Date_ddmmyyyy = Data[6,3]
  Subject = Data[23,3]
  Moment = Data[23,4]
  Birth_ddmmyyyy = Data[25,3]
  Weight_kg = Data[27,3]
  Height_cm = Data[28,3]
  Body_Part = Data[47,3]
  Side = Data[48,3]
  Movement = Data[49,4]

  #compile all variables in a dataframe
  Tableau_recap[i,] = c(CTMFileList[i]
                        , Program
                        , Date_ddmmyyyy
                        , Subject
                        , Moment
                        , Birth_ddmmyyyy
                        , Weight_kg
                        , Height_cm
                        , Body_Part
                        , Side
                        , Movement)
}

#convert variables in right format
Tableau_recap$Program = as.factor(Tableau_recap$Program)
Tableau_recap$Date_ddmmyyyy = as.Date(Tableau_recap$Date_ddmmyyyy
                                      , format = "%d/%m/%Y")
Tableau_recap$Subject = as.factor(Tableau_recap$Subject)
Tableau_recap$Moment = as.factor(Tableau_recap$Moment)
Tableau_recap$Birth_ddmmyyyy = as.Date(Tableau_recap$Birth_ddmmyyyy
                                       , format = "%d/%m/%Y")
Tableau_recap$Weight_kg = as.numeric(Tableau_recap$Weight_kg)
Tableau_recap$Height_cm = as.numeric(Tableau_recap$Height_cm)
Tableau_recap$Body_Part = as.factor(Tableau_recap$Body_Part)
Tableau_recap$Side = as.factor(Tableau_recap$Side)
Tableau_recap$Movement = as.factor(Tableau_recap$Movement)

################################################################################
####STEP 3 : Identification and correction of potential errors in files ####
#show summary from Tableau_recap
Summary_Tableau_recap = summary(Tableau_recap)
print(Summary_Tableau_recap)

#show observations
print("--> observation 1 : manque de données dans la colonne Subject (18 NA) --> même date de naissance, qui est celle du sujet P, donc valeurs manquantes = P")
print("--> observation 2 : manque de données dans la colonne Moment (18 NA) --> même date d'expérimentation, qui est différente de celle du BDC-4, donc valeurs manquantes = R+1")
print("--> observation 3 : erreur d'écriture dans la colonne Moment (17 BDC4 au lieu de BDC-4)")

#corrections
Tableau_recap_corrige = Tableau_recap
Tableau_recap_corrige[is.na(Tableau_recap_corrige$Subject),"Subject"] = "P"
Tableau_recap_corrige[is.na(Tableau_recap_corrige$Moment), "Moment"] = "R+1"
Tableau_recap_corrige$Moment[Tableau_recap_corrige$Moment %in% "BDC4"] = "BDC-4"

#show the new summary
Summary_Tableau_recap_corrige = summary(Tableau_recap_corrige)
print(Summary_Tableau_recap_corrige)

################################################################################
####STEP 4 : save Tableau_recap_corrige in .csv file in RES ####
FileName_Tableau = "Tableau_recap_variables(complet_corrige).csv"
FullFileName_Tableau = file.path(RES_R_PATH,FileName_Tableau)
write.table(Tableau_recap_corrige
            , file = FullFileName_Tableau
            , sep="\t"
            , col.names=T
            , row.names=F
            , quote=F)

Message1 = paste0("Le fichier ",FileName_Tableau," a été enregistré dans RES_R.")
print(Message1)

################################################################################
####STEP 5 : create sub-packages of data depending on conditions ####
##for MVC program (6s = MVC, 90s = Fatigue)
#define conditions
Cat_Body_Part = c("Genou","Cheville")
Cat_Movement = c("Ext","Flex")

#two loops in each other to sort by conditions
for (a in 1:length(Cat_Body_Part)) {
  for (b in 1:length(Cat_Movement)) {
    Paquet_MVC_Body_Part_Movement = Tableau_recap_corrige[(Tableau_recap_corrige$Program == "6s"
                                                           & Tableau_recap_corrige$Body_Part == Cat_Body_Part[a]
                                                           & Tableau_recap_corrige$Movement == Cat_Movement[b]),]
    
    #save sub-package with an appropriate name
    FileName_Paquet = paste0("Tableau_recap_MVC_",Cat_Body_Part[a],"_",Cat_Movement[b],".csv")
    FullFileName_Paquet = file.path(RES_R_PATH,FileName_Paquet)
    write.table(Paquet_MVC_Body_Part_Movement
                , file = FullFileName_Paquet
                , sep="\t"
                , col.names=T
                , row.names=F
                , quote=F)
    
    Message2 = paste0("Le fichier ",FileName_Paquet," a été enregistré dans RES_R.")
    print(Message2)
  }
}

################################################################################
