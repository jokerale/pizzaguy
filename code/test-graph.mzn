include "globals.mzn";


int: k = 6; 
int: E = 8; 

array[1..E] of int: from  = [1, 2, 5, 3, 4, 5, 3, 6]; %,    5, 5, 5,    1];
array[1..E] of int: to    = [2, 3, 1, 4, 5, 6, 6, 1]; %,    2, 3, 4,    5];
array[1..E] of int: w     = [1, 1, 50, 1, 1, 1, 1, 50]; %,    1, 2, 3,    0];

array[1..k] of var bool: ns;
array[1..E] of var bool: es;
var int: W;
array[1..k] of var bool: ns1;
array[1..E] of var bool: es1;
%var int: W1;

constraint bounded_path(k,E,from,to,w,2,1,ns,es,W);
%constraint bounded_path(k,E,from,to,w,2,1,ns1,es1,W1);

constraint ns[3] = true;
constraint ns[4] = true;
constraint ns[5] = true;
constraint ns[6] = true;


solve minimize W;

output %[show(W)] ++["   "]++ [show(W1)] ++ ["\n"] ++
 [show(ns)] ++ ["\t"] ++ [show(es)] ++ ["\n"] ++ [show(W)];
  %++
        %[show(ns1)] ++ ["\t"] ++ [show(es1)];