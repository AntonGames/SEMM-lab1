---- MODULE KerberosAbstract ----
EXTENDS Naturals

CONSTANTS Clients

VARIABLES authState  \* per-client: "idle" or "authenticated"

vars == <<authState>>

TypeOK ==
    authState \in [Clients -> {"idle", "authenticated"}]

Init ==
    authState = [c \in Clients |-> "idle"]

\* A single atomic step: client gets authenticated
Authenticate(c) ==
    /\ authState[c] = "idle"
    /\ authState' = [authState EXCEPT ![c] = "authenticated"]

Next == \E c \in Clients : Authenticate(c)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* ================================================================
\* Properties
\* ================================================================

\* Every client eventually authenticates
EventuallyAuth ==
    \A c \in Clients : <>(authState[c] = "authenticated")

====
