// Calling Sequence
//  [kACT, k1, R2] = ASCENT_CURVE_SIGM(Ascent,Fe)
//
// Authors
//  Manon Faedy - Univ Montpellier - France
//
// Versions
//  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
//
// Description
// ASCENT_CURVE_SIGM is the file of the ASCENT_CURVE_SIGM function to run using
// the scilab interface to obtain as output the two parameters (k1, kACT) of the
// signal modelization (using SIGM function) and the coefficient of correlation
// R2 between the signal and the modelisation, using as input the signal
// ("Ascent") and the sampling frequency (Fe).
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
function [kACT, k1, R2] = ASCENT_CURVE_SIGM(Ascent,Fe)
    //Create Time vector with the same size as Ascent and Fe
    N_Ascent = size(Ascent,'*');
    Time = (0:1/Fe:N_Ascent/Fe)';
    Time = Time(1:$-1);
    
    //Define the initial parameters for the calculation
    N_1 = ones(N_Ascent,1);     //vector full one 1, same size as Ascent
    k1_0 = max(Ascent)-10;      //first value of k1 for calculation is max - 10
    kACT_0 = 0.001;             //first value of kACT for calculation
    factors_0=[k1_0;kACT_0];    //gather factors in 1 vector
    
    //Function to calculate the vector containing the differences between...
    //theoretical and real data at each point
    function e=myfun(x, Time, Ascent, N_1)
       e = N_1.*( SIGM(Time, x) - Ascent );
    endfunction
    
    //Function to solves non-linear least squares problems
    [f,xopt, gopt] = leastsq(list(myfun,Time,Ascent,N_1),factors_0);
    
    //Calculate Theorical_Ascent using SIGM function with the parameters found
    [Theorical_Ascent] = SIGM(Time_Ascent,xopt);
    
    //Extract parameters
    k1 = xopt(1);
    kACT = xopt(2);
    
    //Coefficient of correlation (r^2) between Ascent and Theorical_Ascent
    R2 = correl(Ascent, Theorical_Ascent)^2;
endfunction
