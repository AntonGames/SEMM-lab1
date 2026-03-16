---- MODULE Example ----
VARIABLE x
Init == x = 0
Next == x = 0 /\ x' = 1
Spec == Init /\ [][Next]_x /\ WF_x(Next)

THEOREM TRUE
PROOF OBVIOUS

====
