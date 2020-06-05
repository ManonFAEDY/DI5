// InitTRT initialises the working environment 
//
// Calling Sequence
//  exec("InitTRT.sce")
//
// Parameters
//  None
//  InitTRT must be a script to configure the working environment. 
//  InitTRT is called at the very begining of the main script. 
// 
// Authors
//  Denis Mottet - Univ Montpellier - France
//https://github.com/DenisMot/ScilabDataAnalysisTemplate
//
// Versions
//  Version 2.0.0 -- D. Mottet -- Jun 17, 2011
//  Version 2.1.0 -- D. Mottet -- Oct 10, 2019
//      added getd on directories within PRG_PATH 


////////////////////////////////////////////////////////////////////////////////
// -- Clear workspace
clear ;             // clear all variables
xdel(winsid());     // delete all graphic windows
mode(0);            // to get what is written when you DO NOT add an endding ;


// -- Organize the workspace on the hard disk
// -- The directory structure is :
// - WRK = base directory 
//    - PRG = all program files (.sce and .sci)
//    - DAT = all input data
//    - RES = all results of procesing 
// NOTE : subdirectory are possible, and certainly useful if many files...

// Method 1 : hard code the directory structure (too stupid : forget it!!)

// Method 2 : alternative way, relative to the present file     
PRG_PATH = get_absolute_file_path("InitTRT.sce");
chdir(fullfile(PRG_PATH, ".."));                // up in the directory tree
WRK_PATH = pwd();                               // store the present directory
RES_PATH = fullfile(WRK_PATH, "RES");           // RES, that is within WRK
DAT_PATH = fullfile(WRK_PATH, "DAT");           // DAT, that is within WRK


////////////////////////////////////////////////////////////////////////////////
// -- Load all functions in PRG_PATH

// **** Utility functions to proceed with getd 
function [ListOfDir] = ListDirInDir(Dir)
    // recursively find directory into directory
    ListOfDir = [];
    ff = listfiles(Dir);        
    for i = 1:size(ff,"*")
        f = fullfile(Dir, ff(i));                   // use fullpath (clearer)
        if isdir(f) then
            DirToAdd  = ListDirInDir(f);            // recursion 
            ListOfDir = [ListOfDir; DirToAdd];      // add in list
        end
    end
    ListOfDir = [ListOfDir; Dir]                    // end recursion 
endfunction

function N = NbFilesToGetdInDir(DirToGetd)
    FilesToGetd   = findfiles(DirToGetd, "*.sci");
    N = size(FilesToGetd, "*");
endfunction

// **** proceed with getd 
// find the list of directories inside PRG_PATH
DirToGetd = ListDirInDir(PRG_PATH); 

// count the files in each directory  
NbSciFilesInDir = zeros(DirToGetd); 
for i=1:size(DirToGetd, "r")
    NbSciFilesInDir(i) = NbFilesToGetdInDir(DirToGetd(i));
end

// getd stops if a directory does not contain at least one *.sci 
for i=1:size(DirToGetd, "r")
    if NbSciFilesInDir(i) > 0 then
        getd(DirToGetd(i));                
    end
end

////////////////////////////////////////////////////////////////////////////////
// Inform the user 
clc ;                                       // clear the scialb console
write(%io(2), "")                           // next line 
write(%io(2), "Working directory:")
write(%io(2), "  " + pwd())
write(%io(2), "getd :");
ShortPATH = getrelativefilename(WRK_PATH, PRG_PATH); 
for i=1:size(DirToGetd, "r")
    RelPATH = getrelativefilename(PRG_PATH, DirToGetd(i));
    ThePATH = fullfile(ShortPATH, RelPATH);
    write(%io(2), sprintf("  %d files in %s", NbSciFilesInDir(i), ThePATH) );
end
 clear ShortPATH RelPATH ThePATH NbSciFilesInDir DirToGetd 
