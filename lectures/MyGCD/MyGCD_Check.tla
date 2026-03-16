---- MODULE MyGCD_Check ----
EXTENDS MyGCD
CONSTANT R

\* Correct == (a = b) => a = R
Correct == a = R /\ b = R
ProducesR == <>[](Correct)

====