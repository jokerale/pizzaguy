%%%% V 0.2

% Improvements:
% - Defined new predicate for circuit constraints

% Not working: it can't find solutions, also with 10 minutes of computation.


%%%%%%%%%%%%%%%%%%     INPUT     %%%%%%%%%%%%%%%%%% 


int: d;            % number of delivers

int: start = 19;   % starting service time
int: end   = 22;   % ending service time
int: h     = (end-start) * 2;   % half-an-hours of service 19.00 -> 22.00)


% Graph --> will be given as input
int: k;            % number of nodes ("adresses")
array[1..k, 1..k] of int: mdist; % matrix of distances

% Orders
int: N;
array[1..N] of int: num_pizze;   % array describing the number of pizzas for every order 
array[1..N] of float: orario;    % the decided time of the orders
array[1..N] of int: dest;        % the node where to deliver

array[1..N] of int: ra =         % requested arrival time (in minutes from start time)
  [ round(floor(orario[iN]-start)*60 + (orario[iN] - floor(orario[iN]))*100) | iN in 1..N]; 


%%%%% Input
d=5;

k=5;
mdist = [| 0, 1, 2, 2, 3
         | 1, 0, 2, 2, 3
         | 2, 2, 0, 4, 1
         | 2, 2, 4, 0, 5
         | 3, 3, 1, 5, 0
         |];

N = 8;
orario     =  [19.15, 19.30, 19.30, 20.30, 19.45, 19.30, 20.30, 21.30];
num_pizze  =  [2,     8,     8,     6,     5,     8,     8,     6];
dest       =  [2,     4,     4,     3,     2,     5,     3,     5];
%%%%%





%%%%%%%%%%%%%%%%%%     DECISION VARIABLES     %%%%%%%%%%%%%%%%%% 

array[1..d, 1..N, 1..h] of var bool: scheduling;


% Each element constains the number of pizzas carried in the corresponding half-an-hour
% array[1..d, 1..h] of var 0..16: pizzas_carried;

% array[1..N] of var int: ea; % estimated arrival time for each order 
 array[1..N] of var 0..h*30: ea; % estimated arrival time for each order 

%array[1..d, 1..N, 1..h] of var int: P; % destinations to reach
%array[1..d, 1..N, 1..h] of var 0..k: P; % destinations to reach

%array[1..d, 1..N, 1..h] of var 0..N: X; % positions of the destinations to reach collapsed

%array[1..d, 1..N, 1..h] of var int: distances; % partial distances to reach the node
%array[1..d, 1..N, 1..h] of var 0..30: distances; % partial distances to reach the node





%%%%%%%%%%%%%%%%%%     CONSTRAINTS     %%%%%%%%%%%%%%%%%% 

% All the order must be assigned ...;
constraint sum(scheduling) = N;
% .. to only one deliver.
constraint forall(iN in 1..N)(
    sum([scheduling[id,iN,ih]| id in 1..d, ih in 1..h]) = 1
  );  
  
  
  
  
  
predicate my_circuit(array [1..N] of var bool: sched,
                     array [1..N] of var 0..h*30: ea,
                     int: ih ) = 
  let {
  
    %int: N = card(index_set(sched));
    array[1..N] of var 0..k:   P;   % destinations to reach
    array[1..N] of var 0..N:   X,   % positions of the destinations to reach collapsed
    array[1..N] of var 0..30:  d;   % partial distances to reach the node
  
  }  in
  
  % the arrays must be of the same size
  % index_set(sched) = index_set(ea)
  % /\
  
  forall(iN in 1..N)(
    % P: construction
    (
    P[iN] = sched[iN] * dest[iN]
    )
    /\
    % X: construction
    (
    if P[iN] > 0 then 
      count([ X[iNN] | iNN in 1..N] ,iN,1) 
    else 
      count([ X[iNN] | iNN in 1..N] ,iN,0) 
    endif
    )
    /\
    % X: push 0s at the bottom  
    ( 
    X[iN] = 0 -> forall(j in iN..N) (X[j] = 0)
    )
    /\
    % d: construction
    (
    count([X[iNN]| iNN in 1..N], iN, 0) -> d[iN] = 0
    )
    /\
    (
    if X[iN] !=0 then
      if iN == 1 then
        d[X[iN]] = mdist[1, P[X[iN]]] 
      else
        d[X[iN]] = 
          mdist[P[X[iN - 1]], P[X[iN]]] 
          + sum([d[P[X[iNN]]] | iNN in 1..iN-1])
      endif
    endif
    )
    /\
    % d: hat condition: must go back to pizzeria in 29 minutes
    (
    if X[iN] !=0 then
      if iN+1 == N+1 then
        d[X[iN]] + mdist[P[X[iN]],1] < 30
      else
        if X[iN+1] == 0 then
          d[X[iN]] + mdist[P[X[iN]],1] < 30
        endif
      endif
    endif
    )
    /\
    % "push" results in ea (only significative value of d)
    (
    sched[iN] > 0 -> (ea[iN] = d[iN]+(ih-1)*30)
    )
    
  )

  /\
  
  % max pizzas carried:
  % for each circuit, the sum of pizza carried by deeliverer must be less or equal to 16
  sum([sched[iN]*num_pizze[iN] | iN in 1..N]) <= 16
   
  
  
;




constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
 if (ih*30) < ra[iN] then 
     scheduling[id,iN,ih] = 0
 endif
);
% constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
%  if (ih*30) > (ra[iN]+60) then 
%    scheduling[id,iN,ih] = 0
%  endif
% );

% for each deliverer and for each half-an-hour, the row of scheduling must 
% represent a circuit of nodes to reach
constraint forall(id in 1..d, ih in 1..h)(
  my_circuit([scheduling[id,iN,ih] | iN in 1..N], ea, ih)
);
  
% must arrive in the delivery time window
constraint forall(iN in 1..N)(
  ea[iN] >= ra[iN] /\ ea[iN] < ra[iN]+30 
);






solve satisfy;






output  [show(ea)]; 

%         ["order ID\tdest"] ++ ["\n"] ++
%         ["--------\t----"] ++ ["\n"] ++
%         [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
%         ["\nSCHEDULING\n"] ++
%         ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
%         ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
%         [
%           if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
%           if (j=1) then show(i) ++ "\t" else "" endif ++
%           if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
%           %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
%           if(j=N) then "\n" else "" endif ++
%           if(j=N /\ i=d) then "\n" else "" endif
%             | ih in 1..h, i in 1..d, j in 1..N]
            
%          ++ ["\nexpected arrival: ["] ++ [ show(start+(ea[i] div 60)) ++ "." ++ show(ea[i] mod 60) ++ if i=N then "]" else ", " endif | i in 1..N ];
        