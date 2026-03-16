---- MODULE KerberosRefinement ----
EXTENDS Naturals, TLAPS
CONSTANTS Clients, Server, KDC, Nonces

VARIABLES
    clientState, serverState, kdcState, network, replayCache, usedNonces

vars == <<clientState, serverState, kdcState, network, replayCache, usedNonces>>

K == INSTANCE Kerberos

\* Local alias for TLC cfg file
Spec == K!Spec

\* ================================================================
\* Refinement mapping: concrete -> abstract
\* ================================================================

authState == [c \in Clients |-> IF serverState[c] = "accepted"
                                THEN "authenticated"
                                ELSE "idle"]

Abs == INSTANCE KerberosAbstract WITH authState <- authState

\* ================================================================
\* Refinement claim (checked by TLC, not proved by TLAPS)
\* ================================================================

THEOREM Refinement == K!Spec => Abs!Spec
    OMITTED

\* ================================================================
\* TLAPS proofs
\* ================================================================

AcceptRequiresTicket ==
    \A c \in Clients :
        serverState[c] = "accepted" => c \in kdcState

TypeOK == K!TypeOK

\* ---- Proof: TypeOK is inductive ----
THEOREM TypeInvariant == K!Spec => []TypeOK
    <1>1. K!Init => TypeOK
        BY DEF K!Init, TypeOK, K!TypeOK
    <1>2. TypeOK /\ [K!Next]_vars => TypeOK'
        <2>1. SUFFICES ASSUME TypeOK, [K!Next]_vars PROVE TypeOK'
            OBVIOUS
        <2>2. CASE \E c \in Clients, n \in Nonces : K!ClientRequest(c, n)
            BY <2>2 DEF TypeOK, K!TypeOK, K!ClientRequest, K!Messages
        <2>3. CASE \E msg \in network : K!KDCRespond(msg)
            BY <2>3 DEF TypeOK, K!TypeOK, K!KDCRespond, K!Messages
        <2>4. CASE \E c \in Clients, msg \in network : K!ClientAuthenticate(c, msg)
            BY <2>4 DEF TypeOK, K!TypeOK, K!ClientAuthenticate, K!Messages
        <2>5. CASE \E msg \in network : K!ServerAccept(msg)
            BY <2>5 DEF TypeOK, K!TypeOK, K!ServerAccept, K!Messages
        <2>6. CASE \E msg \in network : K!ServerReject(msg)
            BY <2>6 DEF TypeOK, K!TypeOK, K!ServerReject, K!Messages
        <2>7. CASE \E c \in Clients, msg \in network : K!ClientReceiveOK(c, msg)
            BY <2>7 DEF TypeOK, K!TypeOK, K!ClientReceiveOK, K!Messages
        <2>8. CASE \E msg \in network : K!NetworkLose(msg)
            BY <2>8 DEF TypeOK, K!TypeOK, K!NetworkLose
        <2>9. CASE UNCHANGED vars
            BY <2>9 DEF TypeOK, K!TypeOK, vars
        <2>q. QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9
                  DEF K!Next
    <1>q. QED BY <1>1, <1>2, PTL DEF K!Spec

\* ---- Proof: AcceptRequiresTicket is invariant ----
THEOREM Safety == K!Spec => []AcceptRequiresTicket
    <1>1. K!Init => AcceptRequiresTicket
        BY DEF K!Init, AcceptRequiresTicket
    <1>2. AcceptRequiresTicket /\ TypeOK /\ [K!Next]_vars => AcceptRequiresTicket'
        <2>1. SUFFICES ASSUME AcceptRequiresTicket, TypeOK, [K!Next]_vars
              PROVE AcceptRequiresTicket'
            OBVIOUS
        <2>2. CASE \E c \in Clients, n \in Nonces : K!ClientRequest(c, n)
            BY <2>2 DEF AcceptRequiresTicket, K!ClientRequest
        <2>3. CASE \E msg \in network : K!KDCRespond(msg)
            BY <2>3 DEF AcceptRequiresTicket, K!KDCRespond
        <2>4. CASE \E c \in Clients, msg \in network : K!ClientAuthenticate(c, msg)
            BY <2>4 DEF AcceptRequiresTicket, K!ClientAuthenticate
        <2>5. CASE \E msg \in network : K!ServerAccept(msg)
            BY <2>5 DEF AcceptRequiresTicket, K!ServerAccept
        <2>6. CASE \E msg \in network : K!ServerReject(msg)
            BY <2>6 DEF AcceptRequiresTicket, K!ServerReject
        <2>7. CASE \E c \in Clients, msg \in network : K!ClientReceiveOK(c, msg)
            BY <2>7 DEF AcceptRequiresTicket, K!ClientReceiveOK
        <2>8. CASE \E msg \in network : K!NetworkLose(msg)
            BY <2>8 DEF AcceptRequiresTicket, K!NetworkLose
        <2>9. CASE UNCHANGED vars
            BY <2>9 DEF AcceptRequiresTicket, vars
        <2>q. QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9
                  DEF K!Next
    <1>q. QED BY <1>1, <1>2, TypeInvariant, PTL DEF K!Spec

====
