% Time divided in half-an-hour slots.
% Each deliver has a set of orders assigned to him/her for each slot of time (expressed as boolean matrix - scheduling) 
% Each deliver must reach all nodes of the orders assigned to him/her for each slot of time, starting from pizzeria and get back to it.
% Total travelled distance is minimized. 
% Graph with dummy node.
%
% TO-DO:
% - Add constraints on time of delivery and number of pizzas for each deliver.
%      --> if each deliver can don only one "circuit" for each half-an-hour, we can use 2d array [1..d, 1..h] with pizza handled in the corresponding circuit.
%   DONE: but time constraint is too much simple. 

%  - Think about a "balancing" function to minimize or maximize in addition to minimization of total travelled distance
%      --> but maybe with time-of-delivery constraints the problem of "sparse" deliveries goes away. 

% Don't know why:
% - 2 output



include "globals.mzn";


%% My predicate: a modified bounded_path.
% input: graph related information (like bounded path)
%        and an array x in which x[i] = j means that destination j has to be reached to do the order with ID = i. 
% output: array of int W, in which K[i] = j means that to reach the destination for the order with ID = i the path has weight j. 

% NOT WORKING ANYMORE:
% - B construction: ok.
% - path construction: not ok.
% - how to return the time in which the deliver return to node 1?

% Test code of this predicate in test-predicate.mzn

predicate my_path( % graph
                   int: k, int: E, array [int] of int: from, array [int] of int: to, array [int] of int: w,
                   % path
                   array [int] of var bool: ns, array [int] of var bool: es, array [int] of var int: K, 
                   % input
                   array[int] of var int: x) =

let{
  int: n = card(index_set(x));
  % B contains set of indexes i of x to handle (i s.t. x[i]>0)
  % All the 0s in B are at the end of it.
  array[1..n] of var index_set(x) union {0}: B; 

  array[1..n, 1..k] of var bool: ns;
  array[1..n, 1..E] of var bool: es;

} in

% B construction
  forall(i in 1..n) (
    if x[i]>0 then count_eq(B,i,1) else count_eq(B,i,0) endif
    /\ B[i]=0 -> forall(j in i..n) (B[j] = 0)
    )
     
   /\
% path   
   bounded_path(k,E,from,to,w,1,x[B[1]],[ns[1,j] | j in 1..k],[es[1,j] | j in 1..E], K[B[1]])
   /\
   % I want to say something like:
   % forall(i in 1..n-1) 
   %    find the path from 1 to i (if B[i] != 0) that reach every previous nodes, then W of this path --> K[i] 
   
   % how about path(n-->1) weight, or total weight?  

%   bounded_path(k,E,from,to,w,x[B[1]],x[B[2]],[ns[2,j] | j in 1..k],[es[2,j] | j in 1..E], K[B[2]])
%    forall(i in 1..n-2) (
%      if B[i+1] != 0 then 
%          bounded_path(N,E,from,to,w, x[B[i]], x[B[i+1]], [ns[i+1,j] | j in 1..N], [es[i+1,j] | j in 1..E], K[B[i+1]])
%        else 
%          true 
%        endif)
   
;




%%%%%% INPUT %%%%%%

% Number of delivers
int: d = 2;

% Time of service
int: start = 19;
int: end = 22;

% Half-an-hours of service 
int: h = 6; %(19.00 -> 22.00)

% Graph (with dummy node)

int: k = 4+1; 
int: E = 4+4; 
array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges

% node #5 is a duplicate for root (#1). For allowing bounded_path to work properly. Exists also an edge from 1 to 5 with weigth = 0. 
from  = [1, 1, 1, 2,    5, 5, 5,    1];
to    = [2, 3, 4, 3,    2, 3, 4,    5];
w     = [1, 2, 3, 4,    1, 2, 3,    0];

%       2---3
%       |  /   
%       | /    
%      1(5)----4


% Orders

int: N = 4;
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of float: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver
orario     =  [19.15, 19.30, 19.30, 20.30];
num_pizze  =  [2,     8,     8,     6];
dest       =  [2,     4,     4,     3];


array[1..N] of int: ra = [ round(floor(orario[iN]-start)*60 + (orario[iN] - floor(orario[iN]))*100) | iN in 1..N]; % requested arrival time (in minutes from start time)

%%%%%% DECISION VARIABLES %%%%%%

array[1..d, 1..N, 1..h] of var bool: scheduling;

% Each row contains the nodes (ns) and the edges (es) that deliver reach/use in each half-an-hour
array[1..d, 1..k, 1..h] of var bool: ns;
array[1..d, 1..E, 1..h] of var bool: es;


array[1..d, 1..h] of var int: path_w;

% Each element constains the number of pizzas carried in the corresponding half-an-hour
array[1..d, 1..h] of var int: pizzas_carried;

array[1..N] of var int: ea; % estimated arrival time for each order 


%%%%%% CONSTRAINTS %%%%%%

% All the order must be assigned ...;
constraint sum(scheduling) = N;
% .. to only one deliver.
constraint forall(j in 1..N)(
    sum([scheduling[id,j,ih]| id in 1..d, ih in 1..h]) = 1
  );


% The idea is: for each delivers, must have a path that starts from pizzeria (node 1) and get back to it (node 5 - dummy node for pizzeria)
% and also reachs every node assigned to the deliver.
% LIMIT: only 1 "circuit" for each deliver for each half-an-hour.
% LIMIT: the time to reach a certain destination is set to return time for corresponding circuit.
constraint forall(id in 1..d, ih in 1..h) ( % for each deliver, for each half-an-hour
    bounded_path(k, E, from, to, w, 1, 5, [ns[id,j,ih] | j in 1..k], [es[id,j,ih] | j in 1..E], path_w[id,ih]) /\
    forall(iN in 1..N) (scheduling[id,iN,ih] = true -> (ns[id,dest[iN],ih] = true /\ ea[iN] = (ih-1)*30 + path_w[id,ih]))
    
    
    
    
    % in the future something like
    % my_circuit([scheduling[id,iN,ih]*dest[iN] | iN in 1..N], ... , W)
    
    % max number of pizzas (branch: giacomo)
    % sum([scheduling[id,iN,ih]*num_pizze[iN] | iN in 1..N]) <= 16

    % must arrive in the delivery time window
    %constraint forall(iN in 1..N)(
    %  ea[iN] <= ra[iN]+30 
    %);
  );


% This constraints the number of pizzas that each deliverer can carry in the HALF-AN-HOUR
constraint sum(pizzas_carried) = sum(num_pizze);
constraint forall(id in 1..d, ih in 1..h)(
  pizzas_carried[id, ih] = sum([ num_pizze[j] | j in 1..N where scheduling[id, j, ih] = 1])
  );
constraint forall(id in 1..d, ih in 1..h)( pizzas_carried[id, ih] <= 16 );
constraint forall(id in 1..d, ih in 1..h)( pizzas_carried[id, ih] >= 0   );



% must arrive in the delivery time window
constraint forall(iN in 1..N)(
  ea[iN] > ra[iN] /\ ea[iN] <= ra[iN]+30 
);


%solve satisfy;
solve minimize sum(path_w);




output   
        ["order ID\tdest"] ++ ["\n"] ++
        ["--------\t----"] ++ ["\n"] ++
        [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
        ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
        ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
        [
          if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" else "" endif ++
          if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
          %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
          if(j=N) then "\n" else "" endif ++
          if(j=N /\ i=d) then "\n" else "" endif
            | ih in 1..h, i in 1..d, j in 1..N] ++
        
        ["deliver\t#pizzas\tpath_w\tpath"] ++ ["\n"] ++
        ["-------\t-------\t------\t----"] ++ ["\n"] ++

        [ if i=1 /\ j=1 then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" ++ show(sum([scheduling[i,iN,ih] * num_pizze[iN] | iN in 1..N])) ++"\t" ++ show(path_w[i,ih])++"\t" else "" endif ++

          if fix(es[i,j,ih]) = true then show(from[j]) ++ "<->" ++ show(to[j]) ++ " "  else "" endif ++
                    if(j=E) then "\n" else "" endif ++

          if(j=E /\ i=d) then "\n" else "" endif   

        | ih in 1..h, i in 1..d, j in 1..E] ++
        
        ["Pizzas carried:"] ++ 
        [if j == 1 then "\n d" ++ show(i) ++": "  ++ show(pizzas_carried[i,j]) else " " ++ show(pizzas_carried[i,j]) endif 
        | i in 1..d, j in 1.. h]  ++
        ["\n"] ++
        
        ["tot path weight: " ++ show(sum(path_w))]
        
        ++ ["\nexpected arrival: "] ++ [show(ea)];