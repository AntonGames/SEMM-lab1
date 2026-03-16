---- MODULE MyGCD ----
EXTENDS Naturals
CONSTANT A, B \* Our input.
ASSUME Assm == A \in Nat /\ B \in Nat
VARIABLES a, b
vars == <<a, b>>

TypeOK ==
    /\ a \in Nat
    /\ b \in Nat

\* /\ -- AND
\* \/ -- OR
\* x \in S
Init ==
    /\ a = A
    /\ b = B

StepA ==
    /\ a > b
    /\ a' = a - b
    /\ UNCHANGED b

StepB ==
    /\ b > a
    /\ b' = b - a
    /\ UNCHANGED a

Next == StepA \/ StepB
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

--------

Divides(n, x) == \E y \in 1..n : n = x * y
CommonDivisor(c) == Divides(A, c) /\ Divides(B, c)
GreatestCD(c) ==
    /\ CommonDivisor(c)
    /\ \A d \in 1..c : CommonDivisor(d) => d <= c

EqImpliesGCD == a = b => GreatestCD(a)
EventuallyEq == <>[](a = b)


--------
THEOREM Spec => []EqImpliesGCD
THEOREM Spec => EventuallyEq
------
INSTANCE TLAPS

THEOREM Spec => []TypeOK
    <1>1. Init => TypeOK BY Assm DEF Init, TypeOK
    <1>2. TypeOK /\ [Next]_vars => TypeOK'
        BY DEF TypeOK, Next, vars, StepA, StepB
    <1>q. QED BY <1>1, <1>2, PTL DEF Spec



========
