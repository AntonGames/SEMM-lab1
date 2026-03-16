---- MODULE Round ----
EXTENDS Naturals
CONSTANT Nodes
CONSTANT Rounds
VARIABLE round
VARIABLE done
VARIABLE msgs

vars == <<round, done, msgs>>

TypeOK ==
    /\ round \in [Nodes -> Rounds]
    /\ done  \in [Nodes -> [Rounds -> BOOLEAN]]
    /\ msgs  \in SUBSET [r : Rounds, n : Nodes]
                    \* [{"r", "n"} -> (Rounds \X Nodes)]

RoundDoneSend(n) ==
    LET r == round[n] IN
        /\ ~done[n][r]
     \* /\ done' = [done EXCEPT ![n] = [done[n] EXCEPT ![r] = TRUE] ]
        /\ done' = [done EXCEPT ![n][r] = TRUE]
     \* /\ round' = round
        /\ UNCHANGED round
        /\ msgs' = msgs \cup { [r |-> r, n |-> n] }


RoundDoneRecv(n) ==
    /\ round[n] + 1 \in Rounds \* For TLC only.
    /\ { [r |-> round[n], n |-> nn] : nn \in Nodes } \subseteq msgs
    /\ round' = [round EXCEPT ![n] = @ + 1]
    /\ UNCHANGED <<done, msgs>>

Init ==
    /\ round = [n \in Nodes |-> 0]
    /\ done = [n \in Nodes |-> [ r \in Rounds |-> FALSE ]]
    /\ msgs = {}

Next == \E n \in Nodes :  RoundDoneSend(n) \/ RoundDoneRecv(n)
Fair == WF_vars(Next)
Spec == Init /\ [][Next]_vars /\ Fair

------
RoundActive(r, n) ==
    round[n] = r /\ ~done[n][r]

RoundsIsolated ==
    \A n1, n2 \in Nodes, r1, r2 \in Rounds:
        (RoundActive(r1, n1) /\ RoundActive(r2, n2))
            => r1 = r2

EachRoundReached ==
    \A n \in Nodes, r \in Rounds :
        <>(round[n] = r)

====