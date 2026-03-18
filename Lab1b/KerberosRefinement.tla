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

\* ---- Local copies of definitions for TLAPS ----
\* (TLAPS backends need direct definitions, not via INSTANCE or EXTENDS)

Messages ==
       [type : {"REQ"},   src : Clients, dst : {KDC},    nonce : Nonces]
  \cup [type : {"REPLY"}, src : {KDC},   dst : Clients,  nonce : Nonces, ticket : Clients]
  \cup [type : {"AP"},    src : Clients, dst : {Server},  nonce : Nonces, ticket : Clients]
  \cup [type : {"OK"},    src : {Server}, dst : Clients]

TypeOK ==
    /\ clientState \in [Clients -> {"idle","wait_ticket","wait_auth","done"}]
    /\ serverState \in [Clients -> {"idle","accepted"}]
    /\ kdcState \subseteq Clients
    /\ network \subseteq Messages
    /\ replayCache \subseteq [client : Clients, nonce : Nonces]
    /\ usedNonces \subseteq Nonces

Init ==
    /\ clientState = [c \in Clients |-> "idle"]
    /\ serverState = [c \in Clients |-> "idle"]
    /\ kdcState = {}
    /\ network = {}
    /\ replayCache = {}
    /\ usedNonces = {}

ClientRequest(c, n) ==
    /\ clientState[c] = "idle"
    /\ n \notin usedNonces
    /\ clientState' = [clientState EXCEPT ![c] = "wait_ticket"]
    /\ usedNonces' = usedNonces \cup {n}
    /\ network' = network \cup {[type |-> "REQ", src |-> c, dst |-> KDC, nonce |-> n]}
    /\ UNCHANGED <<serverState, kdcState, replayCache>>

KDCRespond(msg) ==
    /\ msg \in network
    /\ msg.type = "REQ"
    /\ msg.dst = KDC
    /\ kdcState' = kdcState \cup {msg.src}
    /\ network' = (network \ {msg}) \cup
         {[type |-> "REPLY", src |-> KDC, dst |-> msg.src,
           nonce |-> msg.nonce, ticket |-> msg.src]}
    /\ UNCHANGED <<clientState, serverState, replayCache, usedNonces>>

ClientAuthenticate(c, msg) ==
    /\ clientState[c] = "wait_ticket"
    /\ msg \in network
    /\ msg.type = "REPLY"
    /\ msg.dst = c
    /\ clientState' = [clientState EXCEPT ![c] = "wait_auth"]
    /\ network' = (network \ {msg}) \cup
         {[type |-> "AP", src |-> c, dst |-> Server,
           nonce |-> msg.nonce, ticket |-> msg.ticket]}
    /\ UNCHANGED <<serverState, kdcState, replayCache, usedNonces>>

ServerAccept(msg) ==
    /\ msg \in network
    /\ msg.type = "AP"
    /\ msg.dst = Server
    /\ msg.ticket = msg.src
    /\ msg.src \in kdcState
    /\ [client |-> msg.src, nonce |-> msg.nonce] \notin replayCache
    /\ serverState' = [serverState EXCEPT ![msg.src] = "accepted"]
    /\ replayCache' = replayCache \cup {[client |-> msg.src, nonce |-> msg.nonce]}
    /\ network' = (network \ {msg}) \cup
         {[type |-> "OK", src |-> Server, dst |-> msg.src]}
    /\ UNCHANGED <<clientState, kdcState, usedNonces>>

ServerReject(msg) ==
    /\ msg \in network
    /\ msg.type = "AP"
    /\ msg.dst = Server
    /\ \/ msg.ticket # msg.src
       \/ msg.src \notin kdcState
       \/ [client |-> msg.src, nonce |-> msg.nonce] \in replayCache
    /\ network' = network \ {msg}
    /\ UNCHANGED <<clientState, serverState, kdcState, replayCache, usedNonces>>

ClientReceiveOK(c, msg) ==
    /\ clientState[c] = "wait_auth"
    /\ msg \in network
    /\ msg.type = "OK"
    /\ msg.dst = c
    /\ clientState' = [clientState EXCEPT ![c] = "done"]
    /\ network' = network \ {msg}
    /\ UNCHANGED <<serverState, kdcState, replayCache, usedNonces>>

NetworkLose(msg) ==
    /\ msg \in network
    /\ network' = network \ {msg}
    /\ UNCHANGED <<clientState, serverState, kdcState, replayCache, usedNonces>>

Next ==
    \/ \E c \in Clients, n \in Nonces : ClientRequest(c, n)
    \/ \E msg \in network : KDCRespond(msg)
    \/ \E c \in Clients, msg \in network : ClientAuthenticate(c, msg)
    \/ \E msg \in network : ServerAccept(msg)
    \/ \E msg \in network : ServerReject(msg)
    \/ \E c \in Clients, msg \in network : ClientReceiveOK(c, msg)
    \/ \E msg \in network : NetworkLose(msg)

AcceptRequiresTicket ==
    \A c \in Clients :
        serverState[c] = "accepted" => c \in kdcState

\* ================================================================
\* Local spec (identical to K!Spec, but uses local definitions)
\* ================================================================

LocalSpec == Init /\ [][Next]_vars

\* ---- Proof: TypeOK is inductive ----
THEOREM TypeInvariantLocal == LocalSpec => []TypeOK
    <1>1. Init => TypeOK
        BY DEF Init, TypeOK, Messages
    <1>2. TypeOK /\ [Next]_vars => TypeOK'
        <2>1. SUFFICES ASSUME TypeOK, [Next]_vars PROVE TypeOK'
            OBVIOUS
        <2>2. CASE \E c \in Clients, n \in Nonces : ClientRequest(c, n)
            BY <2>1, <2>2, SMT DEF TypeOK, ClientRequest, Messages
        <2>3. CASE \E msg \in network : KDCRespond(msg)
            BY <2>1, <2>3, SMT DEF TypeOK, KDCRespond, Messages
        <2>4. CASE \E c \in Clients, msg \in network : ClientAuthenticate(c, msg)
            BY <2>1, <2>4, SMT DEF TypeOK, ClientAuthenticate, Messages
        <2>5. CASE \E msg \in network : ServerAccept(msg)
            BY <2>1, <2>5, SMT DEF TypeOK, ServerAccept, Messages
        <2>6. CASE \E msg \in network : ServerReject(msg)
            BY <2>1, <2>6, SMT DEF TypeOK, ServerReject, Messages
        <2>7. CASE \E c \in Clients, msg \in network : ClientReceiveOK(c, msg)
            BY <2>1, <2>7, SMT DEF TypeOK, ClientReceiveOK, Messages
        <2>8. CASE \E msg \in network : NetworkLose(msg)
            BY <2>1, <2>8, SMT DEF TypeOK, NetworkLose
        <2>9. CASE UNCHANGED vars
            BY <2>1, <2>9, SMT DEF TypeOK, vars
        <2>q. QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9
                  DEF Next
    <1>q. QED BY <1>1, <1>2, PTL DEF LocalSpec

\* ---- Proof: AcceptRequiresTicket is invariant ----
THEOREM SafetyLocal == LocalSpec => []AcceptRequiresTicket
    <1>1. Init => AcceptRequiresTicket
        BY DEF Init, AcceptRequiresTicket
    <1>2. AcceptRequiresTicket /\ TypeOK /\ [Next]_vars => AcceptRequiresTicket'
        <2>1. SUFFICES ASSUME AcceptRequiresTicket, TypeOK, [Next]_vars
              PROVE AcceptRequiresTicket'
            OBVIOUS
        <2>2. CASE \E c \in Clients, n \in Nonces : ClientRequest(c, n)
            BY <2>1, <2>2, SMT DEF AcceptRequiresTicket, ClientRequest
        <2>3. CASE \E msg \in network : KDCRespond(msg)
            BY <2>1, <2>3, SMT DEF AcceptRequiresTicket, KDCRespond
        <2>4. CASE \E c \in Clients, msg \in network : ClientAuthenticate(c, msg)
            BY <2>1, <2>4, SMT DEF AcceptRequiresTicket, ClientAuthenticate
        <2>5. CASE \E msg \in network : ServerAccept(msg)
            BY <2>1, <2>5, SMT DEF AcceptRequiresTicket, TypeOK, ServerAccept
        <2>6. CASE \E msg \in network : ServerReject(msg)
            BY <2>1, <2>6, SMT DEF AcceptRequiresTicket, ServerReject
        <2>7. CASE \E c \in Clients, msg \in network : ClientReceiveOK(c, msg)
            BY <2>1, <2>7, SMT DEF AcceptRequiresTicket, ClientReceiveOK
        <2>8. CASE \E msg \in network : NetworkLose(msg)
            BY <2>1, <2>8, SMT DEF AcceptRequiresTicket, NetworkLose
        <2>9. CASE UNCHANGED vars
            BY <2>1, <2>9, SMT DEF AcceptRequiresTicket, vars
        <2>q. QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9
                  DEF Next
    <1>q. QED BY <1>1, <1>2, TypeInvariantLocal, PTL DEF LocalSpec

\* ---- Bridge: K!Spec = LocalSpec, so theorems transfer ----
THEOREM TypeInvariant == K!Spec => []TypeOK
    BY TypeInvariantLocal DEF LocalSpec, K!Spec, K!Init, K!Next, K!vars,
       Init, Next, vars, K!ClientRequest, ClientRequest,
       K!KDCRespond, KDCRespond, K!ClientAuthenticate, ClientAuthenticate,
       K!ServerAccept, ServerAccept, K!ServerReject, ServerReject,
       K!ClientReceiveOK, ClientReceiveOK, K!NetworkLose, NetworkLose,
       K!Messages, Messages, K!TypeOK, TypeOK

THEOREM Safety == K!Spec => []AcceptRequiresTicket
    BY SafetyLocal DEF LocalSpec, K!Spec, K!Init, K!Next, K!vars,
       Init, Next, vars, K!ClientRequest, ClientRequest,
       K!KDCRespond, KDCRespond, K!ClientAuthenticate, ClientAuthenticate,
       K!ServerAccept, ServerAccept, K!ServerReject, ServerReject,
       K!ClientReceiveOK, ClientReceiveOK, K!NetworkLose, NetworkLose,
       K!Messages, Messages, K!TypeOK, TypeOK

====
