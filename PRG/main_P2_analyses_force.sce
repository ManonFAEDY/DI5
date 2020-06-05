// Calling Sequence
//  none : main_P2_analyses_force is the entry point 
//
// Authors
//  Manon Faedy - Univ Montpellier - France
//
// Versions
//  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
//
// Description
// main_P2_analyses_force is the file to run using the scilab interface 
// The main_P2_analyses_force script always contains two parts : 
//  1°) set up of working environement 
//  2°) computations (in the right setup) :
//     here analyses of force data
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// **** FIRST : Initialize ****

//  Version 2.1.0 -- D. Mottet -- Oct 10, 2019
//https://github.com/DenisMot/ScilabDataAnalysisTemplate

//get the program path from the file main_P2_analyses_force.cse 
PRG_PATH = get_absolute_file_path("main_P2_analyses_force.sce");
//use the program path to excecute the file InitTRT.sce
FullFileInitTRT = fullfile(PRG_PATH, "InitTRT.sce" );
exec(FullFileInitTRT);

RES_R_PATH = fullfile(RES_PATH, "RES_R");           // RES_R, that is within RES
RES_SCILAB_PATH = fullfile(RES_PATH, "RES_SCILAB"); // RES_SCILAB, that is within RES

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// **** SECOND : Analyses of force datas ****

//STEP 1 : Define sampling frequency and units 
Fe = 256;                       //sampling frequency (Hertz)
Force_unit = "Newton mètres";
Time_Unit = "Secondes";


////////////////////////////////////////////////////////////////////////////////
//STEP 2 : Define conditions to work on (Body_Part, Movement) & open right file

Body_Part = []
Movement = []
//Ask user to choose the wanted condition 
while (Body_Part <> "Cheville" && Body_Part <> "Genou");
    Body_Part = input("Do you want to work on Cheville or Genou data : ", "string");
end

while (Movement <> "Flex" && Movement <> "Ext");
    Movement = input("Do you want to work on Flex or Ext data : ", "string");
end

//Load data
FileName = "Tableau_recap_MVC_"+Body_Part+"_"+Movement+".csv";      //file name corresponding to the chosen conditions
FullFileNamePaquet = fullfile(RES_R_PATH, FileName);                //construct complete file name
Tableau_recap = csvRead(FullFileNamePaquet,ascii(9), [], 'string'); //load the complete file corresponding to the name
Headers = Tableau_recap(1,:);                                       //extract first line as headers
Tableau_recap = Tableau_recap([2:$],:);                             //extract all lines except first one as data

//Recap the chosen conditions
disp("You choosed to work on the body part : "+Body_Part)
disp("You choosed to work on the movement : "+Movement)
disp("The corresponding file for the analysis is "+FileName)

////////////////////////////////////////////////////////////////////////////////
//STEP 3 : Prepare data for limits detection
//Open a loop to load data file listed in Tableau_recap one after the other
for i = 1:size(Tableau_recap,'r')
    Data = fscanfMat(Tableau_recap(i,1));
    //extract the Force from the whole data, corresponding to the first column
    Force = Data(:,1);
    
    //create time vector for Force (same size), using Fe and length of Force
    N_Force = size(Force, 'r');
    Time = (0:1/Fe:N_Force/Fe)';
    Time = Time(1:$-1);
    
    //reverse Force if it is not positive
    if sum(Force) < 0
        then Force = Force.*(-1);
    end
    
    //reduct sampling to simplify Force
    Percent = 1/15;
    Force_M = intdec(Force, Percent);
    
    //create time vector for Force_M
    N_Force_M = size(Force_M, 'r');
    Time_M = (0:1/Fe/Percent:N_Force_M/Fe/Percent)';
    Time_M = Time_M(1:$-1);
    
    //"CLEANING.sci" functionremove artifacts by replacing them by values zero
    Force_M_C = CLEANING(Force_M);
    
    //find max of Force_M_C and its index
    [Max_Force_M_C, i_Max_Force_M_C] = max(Force_M_C);
    Force_M_C_p1 = Force_M_C(1:i_Max_Force_M_C(1));
    
    //derivative calculation
    Diff_Force_M_C = diff(Force_M_C);
    Time_Diff_Force_M = Time_M(1:$-1);
    Diff_Force_M_C_p1 = diff(Force_M_C_p1);
    
    //find max of Diff_Force_M_C and its index
    [Max_Diff_Force_M_C, i_Max_Diff_Force_M_C] = max(Diff_Force_M_C_p1);
    
    
////////////////////////////////////////////////////////////////////////////////
//STEP 4 : Detection of ASCENT OF FORCE phase limits
    //use index of the last value = or < 0 in Ascent as start of Ascent
    i_zero = find(Diff_Force_M_C_p1(1:i_Max_Diff_Force_M_C($)) <= 0);
    //if no value found, research index of value = or < 0 in Diff_Force_M_C_p1 before its max
    if i_zero == []
        then i_zero = find(Force_M_C_p1 == 0);
        //if still no value found, use first value of Ascent
        if i_zero == []
            then i_Start_ascent = 1;
        else i_Start_ascent = i_zero($);
        end
    else i_Start_ascent = i_zero($)+1;
    end
    Time_Start_ascent = Time_M(i_Start_ascent);
    
    
    //use index of the first value = or < 0 in Diff_Force_M_C_p1 after i_Start_ascent
    i_zero_diff = find(Diff_Force_M_C_p1(i_Start_ascent:$) <= 0);
    //if no values found, use index of last value of Ascent
    if i_zero_diff == []
        then i_End_ascent = size(Force_M_C_p1,'r');
    else i_End_ascent = i_Start_ascent + i_zero_diff(1);
    end
    Time_End_ascent = Time_M(i_End_ascent);
    
    
    //don't use limits if Signal at End_ascent < half max MVC
    if Force_M_C_p1(i_End_ascent) < (Max_Force_M_C/2)
        then Time_End_ascent = []
    end

////////////////////////////////////////////////////////////////////////////////
//STEP 5 : Plotting Force with limits
    figure(i);
    subplot(2,1,1)
    plot(Time, Force,'r');
    plot(Time_Diff_Force_M, Diff_Force_M_C,'b');
    
    //if still no limits values, disp error message, else add limits on plot
    if Time_Start_ascent == []|Time_End_ascent == []...
        |Time_Start_ascent == 0 |Time_End_ascent == 0
        then
        disp("Curve number "+string(i)+" could not been done.");
        Time_Start_ascent = 0;
        Time_End_ascent = 0;
    else
        plot([Time_Start_ascent Time_Start_ascent],[0 max(Force)],'y');
        plot([Time_End_ascent Time_End_ascent],[0 max(Force)],'--y');
    end
    
    //add name on plot with conditions and suject ID
    legend("Force", "Derivative Force","Start_ascent", "End_ascent",-1);
    TryName = "MVC "+Body_Part+" "+Movement+" subject "+...
    string(Tableau_recap(i,4))+" "+string(Tableau_recap(i,5));
    xtitle([TryName;Tableau_recap(i,1)],Time_Unit,Force_unit, boxed = %t);
    
    
////////////////////////////////////////////////////////////////////////////////
//STEP 6 : Modelization of ascent of force
    if Time_Start_ascent == 0 |Time_End_ascent == 0
        then
        kACT = 0;
        k1 = 0;
        R2 = 0;
    else
        Start = find(Time >= Time_Start_ascent);
        End = find(Time >= Time_End_ascent);
        
        Ascent = Force(Start(1):End(1));
        N_Ascent = size(Ascent, 'r');
        
        Time_Ascent = (0:1/Fe:N_Ascent/Fe)';
        Time_Ascent = Time_Ascent(1:$-1);
        
        [kACT, k1, R2] = ASCENT_CURVE_SIGM(Ascent,Fe);
        
        
        //Recreate theorical Ascent with parameter in the SIGM function
        factors = [k1,kACT];
        Theorical_Ascent = SIGM(Time_Ascent, factors);
        
        
    ////////////////////////////////////////////////////////////////////////////////
    //STEP 7 : Plotting Force with model
        figure(i)
        subplot(2,1,2);
        plot(Time_Ascent,Ascent,'r');
        plot(Time_Ascent,Theorical_Ascent,'g');
        
        legend("Ascent", "Theorical_Ascent",-1);
        TryName = "Modelization of Ascent of MVC "+Body_Part+" "+Movement+...
        " subject "+string(Tableau_recap(i,4))+" "+string(Tableau_recap(i,5));
        xtitle([TryName;Tableau_recap(i,1)],Time_Unit,Force_unit, boxed = %t);
    end
    
////////////////////////////////////////////////////////////////////////////////
//STEP 8 : Save plot in pdf
    PLOT_PATH = fullfile(RES_SCILAB_PATH, "Plots_Scilab");
    FileNamePlot = "Plot_Ascent_MVC_"+Body_Part+"_"+Movement+"_"+string(i)+".pdf";
    FullFileNamePlot = fullfile(PLOT_PATH, FileNamePlot);
    xs2pdf(i,FullFileNamePlot);
    
    
////////////////////////////////////////////////////////////////////////////////
//STEP 9 : Compile results
    //compile result with Tableau_recap
    Tableau_recap_resultats(i,:) = [Tableau_recap(i,:),...
    string(Time_Start_ascent), string(Time_End_ascent), string(k1),...
    string(kACT),string(R2)];
    
    //Clear vectors/matrix to remove data from the previous loop
    clear Potentiel_Data Force Time Force_M Force_M_C Diff_Force_M_C Time_Diff_Force_M
    
end

//complete and add headers to Tableau_recap_resultats
Headers = [Headers, "Start_ascent","End_ascent", "k1", "kACT","R2"];
Tableau_recap_resultats = [Headers ; Tableau_recap_resultats];


////////////////////////////////////////////////////////////////////////////////
//STEP 10 :Save Tableau_recap_resultats as a csv file in RES_SCILAB repertory
FileNameTableau_recap_resultats = "Tableau_recap_MVC_"+Body_Part+"_"+...
Movement+"_Resultats.csv";
FullFileNameTableau_recap_resultats = fullfile(RES_SCILAB_PATH,...
FileNameTableau_recap_resultats);
csvWrite(Tableau_recap_resultats, FullFileNameTableau_recap_resultats,...
ascii(9),'.');

////////////////////////////////////////////////////////////////////////////////
