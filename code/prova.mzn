% Objective: create a predicate my_path(x,W)
% where
%   x: 'scheduling' line (array 1..N) with order's destinations (eg. [2,0,0,5])
%   W: array 1..N --> W[i] = j means that to reach the ith order's destination there is a weight of j.    
%
% Obtained W will be used for delivery time constraint in 'pizzaguy'. 

include "globals.mzn";

int: N = 4;


% INPUT 
array[1..N] of int: dest = [2,3,4,5];
array[1..N] of var int: scheduling = [1,0,0,1];




%%constraint aaa([dest[i]*scheduling[i]| i in 1..N]);

% future input
array[int] of var int: x = [dest[i]*scheduling[i]| i in 1..N];



var set of index_set(x): A; % will contain all and only the elements i for which x[i] contains a destination.
int: n = card(index_set(x));

array[1..n] of var int: B;

% put in A only the positions of x in which there are a destination to reach.
constraint forall(i in 1..n) (if x[i]>0 then i in A else not(i in A) endif);

% I can't do: forall(i in A) (bounded_path i --> i+1) . What does 'i' means? And 'i+1'?
% So, I want something like this:

% B = an array that contains all and only elements of A --> without caring about the order <-- IMPORTANT: allows all the combinations of paths
%
% For allowing:
%   bounded_path(1,B[1],...W[B[1]]) /\ % start from pizzeria
%   forall(i in 2..card(B)-1) (bounded_path(B[i],B[i+1]),..., W[B[i+1]]) /\
%   bounded_path(B[card(B)],1,..., W[B[card(B)]]) % get back to pizzeria
%
% path: 1 --> B[1] --> B[2] --> B[n] --> 1







%% PREDICATE

% predicate aaa(array[int] of var int: x) =

% let{

%   var set of index_set(x): A;
%   int: n = card(index_set(x));
%   array[1..n] of var int: B;

% } in

% % put in A only the positions of x in which there are a destination to reach.
% forall(i in 1..n) (if x[i]>0 then i in A else not (i in A) endif);

%% ----




solve satisfy;

output [show(A)]++["\n"];