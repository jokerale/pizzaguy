include "globals.mzn";


int: k = 5; 
int: E = 6; 

array[1..E] of int: from  = [1, 1, 1, 2, 3, 5]; %,    5, 5, 5,    1];
array[1..E] of int: to    = [2, 3, 4, 3, 5, 1]; %,    2, 3, 4,    5];
array[1..E] of int: w     = [1, 5, 3, 4, 1, 1]; %,    1, 2, 3,    0];

array[1..k] of var bool: ns;
array[1..E] of var bool: es;
var int: W;
array[1..k] of var bool: ns1;
array[1..E] of var bool: es1;
var int: W1;

constraint bounded_path(k,E,from,to,w,1,2,ns,es,W);
constraint bounded_path(k,E,from,to,w,2,1,ns1,es1,W1);

constraint ns1[3] = true;
constraint ns1[5] = true;


solve minimize W + W1;

output [show(W)] ++["   "]++ [show(W1)] ++ ["\n"] ++
 [show(ns)] ++ ["\t"] ++ [show(es)] ++ ["\n"] ++
        [show(ns1)] ++ ["\t"] ++ [show(es1)];