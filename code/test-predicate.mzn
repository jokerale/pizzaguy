% Objective: create a predicate my_path(x,W)
% where
%   x: 'scheduling' line (array 1..N) with order's destinations (eg. [2,0,0,5])
%   W: array 1..N --> W[i] = j means that to reach the ith order's destination there is a weight of j.    
%
% Obtained W will be used for delivery time constraint in 'pizzaguy'. 

include "globals.mzn";

int: N = 4;
array[1..N] of int: dest = [2,3,4,4];
array[1..N] of var int: scheduling = [1,0,0,1];

int: k = 4; 
int: E = 4; 
array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges

% node #5 is a duplicate for root (#1). For allowing bounded_path to work properly. Exists also an edge from 1 to 5 with weigth = 0. 
from  = [1, 1, 1, 2];
to    = [2, 3, 4, 3];
w     = [1, 2, 3, 4];

% bounded_path(k, E, from, to, w, 1, 5, [ns[id,j,ih] | j in 1..k], [es[id,j,ih] | j in 1..E], path_w[id,ih])

  array[1..n, 1..k] of var bool: ns;
  array[1..n, 1..E] of var bool: es;
array[1..N] of var int: W;


predicate aaa(         % graph
                       int: k,
                       int: E,
                       array [int] of int: from,
                       array [int] of int: to,
                       array [int] of int: w,
                       array [int] of var bool: ns,
                       array [int] of var bool: es,
                       array [int] of var int: K, % weight      %var int: K,
                       array[int] of var int: x) =

let{
  int: n = card(index_set(x));
  array[1..n] of var index_set(x) union {0}: B; % set of indexes of x to reach
%   array[1..n] of var lb_array(x)..ub_array(x): A; % x ordered
%   var int: number_of_zeros = sum([x[i]=0 | i in 1..N]);   
  
  array[1..n] of var int: t; % temporary paths' weights
  
  array[1..n, 1..k] of var bool: ns;
  array[1..n, 1..E] of var bool: es;
%   array[int] of var int: X = [x[i]>0 | i in 1..card(index_set(x))];
%   var set of 1..2: A;
%   array2set(x): B;
%   array[int] of var int: A = x;
%   int: max = max(fix(A));
%   int: N = card(index_set(x));
%   var set of 1..max: S;

} in

% B (and t) construction -- it really works?
  forall(i in 1..n) (if x[i]>0 then count_eq(B,i,1) else count_eq(B,i,0) endif)
  /\
  forall(i in 1..n) (B[i]=0 -> forall(j in i..n) (B[j] = 0))
%  /\
%  forall(i in 1..n) (B[i]=0 -> t[i]=0)
    
     
   /\
% path   
   bounded_path(k,E,from,to,w,1,x[B[1]],[ns[1,j] | j in 1..k],[es[1,j] | j in 1..E], t[1])
   /\
   forall(i in 1..n-1 where B[i+1]>0)(
     %if B[i+1] != 0 then
       bounded_path(k,E,from,to,w,x[B[i]],x[B[i+1]],[ns[i+1,j] | j in 1..k],[es[i+1,j] | j in 1..E], t[i+1])
     %else
     %  t[i+1] = 0
     %endif
     )
   % I want to say something like:
   % forall(i in 1..n-1) 
   %    find the path from 1 to i (if B[i] != 0) that reach every previous nodes, then W of this path --> K[i] 

%   bounded_path(k,E,from,to,w,x[B[1]],x[B[2]],[ns[2,j] | j in 1..k],[es[2,j] | j in 1..E], K[B[2]])
%    forall(i in 1..n-2) (
%      if B[i+1] != 0 then 
%          bounded_path(N,E,from,to,w, x[B[i]], x[B[i+1]], [ns[i+1,j] | j in 1..N], [es[i+1,j] | j in 1..E], K[B[i+1]])
%        else 
%          true 
%        endif)

   
  /\ 
  forall(i in 1..n) (W[i] = t[i]) %if B[i] > 0 then W[B[i]] = sum([t[j] | j in 1..i]) else true endif)      
            
;
%%

%constraint aaa([dest[i]*scheduling[i] | i in 1..N]);


%constraint aaa(k,E,from,to,w,[ns[1,i] | i in 1..k],[ns[1,i] | i in 1..E],W,[dest[i]*scheduling[i]| i in 1..N]);

 array[int] of var int: x = [dest[i]*scheduling[i]| i in 1..N];


% %var set of index_set(x): A;

            
%                                     %/\ alldifferent_except_0(B);

 int: n = card(index_set(x));

 array[1..n] of var index_set(x) union {0}: B;

 constraint forall(i in 1..n) (if x[i]>0 then count_eq(B,i,1) else count_eq(B,i,0) endif);
 constraint forall(i in 1..n) (B[i]=0 -> forall(j in i..n) (B[j] = 0));
 constraint alldifferent_except_0(B);

array[1..n] of var int: t;
constraint forall(i in 1..n)(t[i]>=0);
array[1..n] of var int: ttt;

constraint 
  bounded_path(k,E,from,to,w,1,x[B[1]],[ns[1,j] | j in 1..k],[es[1,j] | j in 1..E], t[1]);
%constraint
%  bounded_path(k,E,from,to,w,x[B[1]],x[B[2]],[ns[2,j] | j in 1..k],[es[2,j] | j in 1..E], t[2]) ;
  %/\
  %bounded_path(k,E,from,to,w,x[B[2]],x[B[3]],[ns[3,j] | j in 1..k],[es[3,j] | j in 1..E], t[3]);
constraint forall(i,j in 1..n-1 where j=i+1)(
  %if B[j] != 0 then bounded_path(k,E,from,to,w,x[B[i]],x[B[j]],[ns[j,w] | w in 1..k],[es[j,w] | w in 1..E], t[j])
  %else true endif
  B[j] > 0 -> bounded_path(k,E,from,to,w,x[B[i]],x[B[j]],[ns[j,w] | w in 1..k],[es[j,w] | w in 1..E], t[j]) 
 %true
   );



%    forall(i in 1..n-1 where B[i+1]>0)(
%      %if B[i+1] != 0 then
%        bounded_path(k,E,from,to,w,x[B[i]],x[B[i+1]],[ns[i+1,j] | j in 1..k],[es[i+1,j] | j in 1..E], t[i+1])
%      %else
%      %  t[i+1] = 0
%      %endif
%      );

          
          
                              % /\ value_precede
% constraint forall(i in 1..n) (if x[i]>0 then i in A else not(i in A) endif);
% constraint forall(i in 1..n) (B[i] in A union {0});


%constraint forall(i in A, j in 1..n) (B[j] = i);



%array[int] of var int: X = [if x[i]>0 then x[i] else endif | i in 1..card(index_set(x))];


solve satisfy;

output %[show(A)]++["\n"]
     ["x: "] ++ [show(x)] ++ ["\n"] ++
     ["B: "] ++ [show(B)] ++ ["\n"] ++
     ["t: "] ++ [show(t)] ++ ["\n"] ++
     ["ttt: "] ++ [show(ttt)] ++ ["\n"] ++
      ["W: "] ++ [show(W)] ++ ["\n"];