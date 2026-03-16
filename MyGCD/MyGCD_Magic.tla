---- MODULE MyGCD_Magic ----
EXTENDS Naturals
CONSTANT A, B \* Our input.
ASSUME Assm == A \in Nat /\ B \in Nat
VARIABLES a, b
vars == <<a, b>>

TypeOK ==
    /\ a \in Nat
    /\ b \in Nat

Divides(n, x) == \E y \in 1..n : n = x * y
CommonDivisor(c) == Divides(A, c) /\ Divides(B, c)
GreatestCD(c) ==
    /\ CommonDivisor(c)
    /\ \A d \in 1..c : CommonDivisor(d) => d <= c

Init ==
    /\ a = A
    /\ b = B

Next ==
    \E x \in 1..A :
        /\ GreatestCD(x)
        /\ a' = x
        /\ b' = x

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

EqImpliesGCD == a = b => GreatestCD(a)
EventuallyEq == <>[](a = b)

====