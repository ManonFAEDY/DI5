// Calling Sequence
//  Signal_clean = CLEANING(Signal)
//
// Authors
//  Manon Faedy - Univ Montpellier - France
//
// Versions
//  Version 1.0.0 -- M.FAEDY -- Mai 10, 2020
//
// Description
// CLEANING is the file of the CLEANING function to run using the scilab interface 
// to obtain as output the same vector of data as in input but cleaned,
// meaning without the artefacts before and after the principal part of the curve.
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
function Signal_clean = CLEANING(Signal)
    //find index of the max of Signal
    [Max_Signal,I_Max_Signal] = max(Signal);
    
    //extract 2 parts of the Signal cutting at I_Max_Signal
    //in case of multiples max use I_Max_Signal(1)
    P1 = Signal(1:I_Max_Signal(1));
    P2 = Signal(I_Max_Signal(1):$);
    
    //define the threshold value
    TS = 1;
    
    //find in each part signal the index of data under TS
    Starts = find(P1 < TS);
    Ends = find(P2 < TS);
    
    //open if loop in case of no values in Starts
    if Starts <> []
        then
        //replace every values before the last one under TS by zero
        P1(1:Starts($)) = [0];
    end
    
    //open if loop in case of no values in Ends
    if Ends <> []
        then
        //replace every values after the last one under TS by zero
        P2(Ends(1):$) = [0];
    end
    
    //concatenate the full Signal_clean from P1 and P2 parts
    // if loop to give to Signal_clean the same dimensions as Signal
    if size(Signal,'r') > size(Signal,'c');
        then
        Signal_clean = [P1;P2(2:$)];
    else
        Signal_clean = [P1,P2(2:$)];
        //as P1 and P2 share the max value, need to take P2 from 2nd value
    end
    
endfunction
////////////////////////////////////////////////////////////////////////////////
