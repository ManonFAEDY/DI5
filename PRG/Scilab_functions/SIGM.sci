// Calling Sequence
//  y=SIGM(time, factors)
//
// Authors
//  Manon Faedy - Univ Montpellier - France
//
// Versions
//  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
//
// Description
// SIGM is the file of the SIGM function to run using the scilab interface 
// to obtain as output a vector "y" of data calculated on a sigmoïde base
// using as input a time vector and a parameters vector (k1, kACT).

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
function y=SIGM(time, factors)
    //calculate length of vector time
    N_time = size(time,'*');
    //open a loop to calculate y value on each point of time
    for j = 1:N_time
        //factors(1) represente k1
        //factors(2) represente kACT
        y(j) = factors(1) / (1+ abs(1/ (factors(2) * time(j)))^exp(1));
        //using an absolute value in formula to avoid complex number problems
    end
endfunction
////////////////////////////////////////////////////////////////////////////////
