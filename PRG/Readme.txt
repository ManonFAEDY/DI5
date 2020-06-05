# ScilabRStudioDataAnalysisTemplate
This is a template for data analysis with Scilab and RStudio.  
It is mainly intended to facilitate use and minimise potential errors by :
* enforcing a consistent directory structure 
For each novel data analysis problem, the idea is to create a novel directory containing *at least*
	* `PRG`: R and Scilab scripts and functions for the analyses 
		* 'R_functions’ : R functions for the analyses
		* 'Scilab_functions’: Scilab functions for the analyses


* compiling all functions in `PRG` when you run `main_P2_analyses_force.sce`   
This is handy, somewhat similar to matlab's way of doing, *though you must re-run main each time you modify a function*  
This is done in `InitTRT.sce`
Functions are almost always in an independent file which contains only the function and its description.


## Usage
* (Clone or) download the repository 
* On your computer : 
	* Open and run files in the following order:
		* 'main_P1_tri_correction_paquets.R' in RStudio
		* 'main_P2_analyses_force.sce' in Scilab
		* 'main_P3_STATS_force.R' in RStudio

## Notes : 
* You first need to install [Scilab](http://www.scilab.org), [R] and [RStudio]...
* Double click on `main_P2_analyses_force.sce` might not work... depending on your OS.  
Opening files from SciNotes allways works (File menu -> open). 
* *Do not modify the names and organisation of the directories*   
The DAT+PRG+RES structure is expected when initialising in `InitTRT.sce`