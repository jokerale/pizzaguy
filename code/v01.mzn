include "globals.mzn";

%%%%%% INPUT %%%%%%

% Number of delivers
int: d = 2;

% Time of service
int: start = 19;
int: end = 22;

% Half-an-hours of service 
int: h = 6; %(19.00 -> 22.00)


% Graph 
int: k = 5;
array[1..k, 1..k] of var int: mdist; % matrix of distances
mdist = [| 0, 1, 2, 2, 3
         | 1, 0, 2, 3, 3
         | 2, 2, 0, 4, 1
         | 2, 3, 4, 0, 5
         | 3, 3, 1, 5, 0
         |];



% Orders

int: N = 8;
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of float: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver
orario     =  [19.15, 19.30, 19.30, 20.30, 19.45, 19.30, 20.30, 21.30];
num_pizze  =  [2,     8,     8,     6,     5,     8,     8,     6];
dest       =  [2,     4,     4,     3,     2,     5,     3,     5];

% constraint scheduling[1,1,2] = 1;
% constraint scheduling[1,8,6] = 1;
% constraint scheduling[1,2,2] = 1;
% constraint scheduling[1,5,2] = 1;
% constraint scheduling[2,3,2] = 1;
array[1..N] of int: ra = [ round(floor(orario[iN]-start)*60 + (orario[iN] - floor(orario[iN]))*100) | iN in 1..N]; % requested arrival time (in minutes from start time)

%%%%%% DECISION VARIABLES %%%%%%

array[1..d, 1..N, 1..h] of var bool: scheduling;


% Each element constains the number of pizzas carried in the corresponding half-an-hour
array[1..d, 1..h] of var int: pizzas_carried;

array[1..N] of var int: ea; % estimated arrival time for each order 

array[1..d, 1..N, 1..h] of var int: P; % destinations to reach
array[1..d, 1..N, 1..h] of var 0..N: X; % positions of the destinations to reach collapsed
array[1..d, 1..N, 1..h] of var int: distances; % partial distances to reach the node

%%%%%% CONSTRAINTS %%%%%%

% All the order must be assigned ...;
constraint sum(scheduling) = N;
% .. to only one deliver.
constraint forall(j in 1..N)(
    sum([scheduling[id,j,ih]| id in 1..d, ih in 1..h]) = 1
  );
  
% P consistency
constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  P[id, iN, ih] = scheduling[id, iN, ih] * dest[iN]
);
% X consistency
constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  if P[id, iN, ih] > 0 then 
%   if P[id, iN, ih] != 0 then
    count([ X[id, iNN, ih] | iNN in 1..N] ,iN,1) 
    else 
    count([ X[id, iNN, ih] | iNN in 1..N] ,iN,0) 
  endif
  /\
  % push 0s at the bottom  
  ( X[id,iN,ih]=0 -> forall(j in iN..N) (X[id,j,ih] = 0) )
);

% distances consistency
constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
   distances[id, iN, ih] >= 0
%     /\
%     distances[id, iN, ih] <= 30
);

constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  count([X[id,iNN,ih]| iNN in 1..N], iN, 0) -> distances[id,iN,ih] = 0
);

constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
  % calculate distances
  
  if X[id,iN,ih] !=0 then
  
    if iN == 1 then
      distances[id, X[id,iN,ih], ih] = mdist[1, P[id, X[id,iN,ih], ih]] 
    else
      distances[id, X[id,iN,ih], ih] = 
         mdist[P[id, X[id,iN - 1,ih], ih], P[id, X[id,iN,ih], ih]] 
         + sum([distances[id,P[id, X[id,iNN,ih], ih],ih] | iNN in 1..iN-1])
       
    endif
  
  endif
  
);

constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
  % add constraint on total distances
  if X[id,iN,ih] !=0 then
    if iN+1 == N+1 then
      distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] <= 30
      %/\
      %distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] >= (ih-1)*30
    else
      if X[id,iN+1,ih] == 0 then
        distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] <= 30
        %/\
        %distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] >= (ih-1)*30
      endif
    endif
    
  endif
);

constraint forall(j in 1..N)(
    ea[j] = sum([scheduling[id,j,ih] * (distances[id,j,ih]+((ih-1)*30)) | id in 1..d, ih in 1..h])  
    %ea[j] = sum([(distances[id,j,ih]+((ih-1)*30)) | id in 1..d, ih in 1..h])  
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

solve :: int_search( distances,
        dom_w_deg, indomain_random) satisfy;
%solve satisfy;
%solve minimize sum(ea);


output   

        ["order ID\tdest"] ++ ["\n"] ++
        ["--------\t----"] ++ ["\n"] ++
        [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
        ["\nSCHEDULING\n"] ++
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
            
        ["\nP\n"] ++    
        ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
        ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
        [
          if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" else "" endif ++
          show(P[i,j,ih]) ++ "\t" ++
          %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
          if(j=N) then "\n" else "" endif ++
          if(j=N /\ i=d) then "\n" else "" endif
            | ih in 1..h, i in 1..d, j in 1..N] ++
        
        ["\nX\n"] ++
        ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
        ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
        [
          if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" else "" endif ++
          show(X[i,j,ih]) ++ "\t" ++
          %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
          if(j=N) then "\n" else "" endif ++
          if(j=N /\ i=d) then "\n" else "" endif
            | ih in 1..h, i in 1..d, j in 1..N] ++
        
        ["\ndistances*scheduling\n"] ++
        ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
        ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
        [
          if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" else "" endif ++
          show((distances[i,j,ih]+((ih-1)*30))*scheduling[i,j,ih]) ++ "\t" ++
          %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
          if(j=N) then "\n" else "" endif ++
          if(j=N /\ i=d) then "\n" else "" endif
            | ih in 1..h, i in 1..d, j in 1..N] ++
            
        ["\nexpected arrival: ["] ++ [ show(start+(ea[i] div 60)) ++ "." ++ show(ea[i] mod 60) ++ if i=N then "]" else ", " endif | i in 1..N ] 
        
        ++["\nra: "] ++ [show(ra)];
        
          

%         ["order ID\tdest"] ++ ["\n"] ++
%         ["--------\t----"] ++ ["\n"] ++
%         [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
%         ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
%         ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
%         [
%           if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
%           if (j=1) then show(i) ++ "\t" else "" endif ++
%           if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
%           %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
%           if(j=N) then "\n" else "" endif ++
%           if(j=N /\ i=d) then "\n" else "" endif
%             | ih in 1..h, i in 1..d, j in 1..N] ++
        
%         ["deliver\t#pizzas\tpath_w\tpath"] ++ ["\n"] ++
%         ["-------\t-------\t------\t----"] ++ ["\n"] ++

%         [ if i=1 /\ j=1 then "(h"++show(ih)++")\n" else "" endif ++
%           if (j=1) then show(i) ++ "\t" ++ show(sum([scheduling[i,iN,ih] * num_pizze[iN] | iN in 1..N])) ++"\t" ++ show(path_w[i,ih])++"\t" else "" endif ++

%           if fix(es[i,j,ih]) = true then show(from[j]) ++ "<->" ++ show(to[j]) ++ " "  else "" endif ++
%                     if(j=E) then "\n" else "" endif ++

%           if(j=E /\ i=d) then "\n" else "" endif   

%         | ih in 1..h, i in 1..d, j in 1..E] ++
        
%         ["Pizzas carried:"] ++ 
%         [if j == 1 then "\n d" ++ show(i) ++": "  ++ show(pizzas_carried[i,j]) else " " ++ show(pizzas_carried[i,j]) endif 
%         | i in 1..d, j in 1.. h]  ++
%         ["\n"] ++
        
%         ["tot path weight: " ++ show(sum(path_w))]
        
%         ++ ["\nexpected arrival: ["] ++ [ show(start+(ea[i] div 60)) ++ "." ++ show(ea[i] mod 60) ++ if i=N then "]" else ", " endif | i in 1..N ];