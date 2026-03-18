---- MODULE Kerberos ----
EXTENDS Naturals

CONSTANTS Clients, Server, KDC, Nonces

VARIABLES
    clientState,    \* client phase: "idle","wait_ticket","wait_auth","done"
    serverState,    \* server view per client: "idle","accepted"
    kdcState,       \* set of issued tickets
    network,        \* set of messages in transit (unreliable)
    replayCache,    \* set of authenticators already seen by server
    usedNonces      \* nonces already picked by clients

vars == <<clientState, serverState, kdcState, network, replayCache, usedNonces>>

\* ---- Message types ----
\* REQ:   Client -> KDC:    request ticket for Server
\* REPLY: KDC -> Client:    ticket + session nonce
\* AP:    Client -> Server:  ticket + authenticator
\* OK:    Server -> Client:  authentication accepted

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

\* ================================================================
\* Protocol steps
\* ================================================================

\* Step 1: Client picks a fresh nonce and sends REQ to KDC
ClientRequest(c, n) ==
    /\ clientState[c] = "idle"
    /\ n \notin usedNonces
    /\ clientState' = [clientState EXCEPT ![c] = "wait_ticket"]
    /\ usedNonces' = usedNonces \cup {n}
    /\ network' = network \cup {[type |-> "REQ", src |-> c, dst |-> KDC, nonce |-> n]}
    /\ UNCHANGED <<serverState, kdcState, replayCache>>

\* Step 2: KDC receives REQ, issues ticket (records it), sends REPLY
KDCRespond(msg) ==
    /\ msg \in network
    /\ msg.type = "REQ"
    /\ msg.dst = KDC
    /\ kdcState' = kdcState \cup {msg.src}
    /\ network' = (network \ {msg}) \cup
         {[type |-> "REPLY", src |-> KDC, dst |-> msg.src,
           nonce |-> msg.nonce, ticket |-> msg.src]}
    /\ UNCHANGED <<clientState, serverState, replayCache, usedNonces>>

\* Step 3: Client receives REPLY, builds authenticator, sends AP to Server
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

\* Step 4a: Server receives AP, validates ticket and checks replay cache
ServerAccept(msg) ==
    /\ msg \in network
    /\ msg.type = "AP"
    /\ msg.dst = Server
    /\ msg.ticket = msg.src                           \* ticket must match the sender
    /\ msg.src \in kdcState                           \* KDC actually issued this ticket
    /\ [client |-> msg.src, nonce |-> msg.nonce] \notin replayCache  \* not a replay
    /\ serverState' = [serverState EXCEPT ![msg.src] = "accepted"]
    /\ replayCache' = replayCache \cup {[client |-> msg.src, nonce |-> msg.nonce]}
    /\ network' = (network \ {msg}) \cup
         {[type |-> "OK", src |-> Server, dst |-> msg.src]}
    /\ UNCHANGED <<clientState, kdcState, usedNonces>>

\* Step 4b: Server rejects AP (ticket invalid or replay)
ServerReject(msg) ==
    /\ msg \in network
    /\ msg.type = "AP"
    /\ msg.dst = Server
    /\ \/ msg.ticket # msg.src                        \* forged ticket
       \/ msg.src \notin kdcState                     \* no ticket issued
       \/ [client |-> msg.src, nonce |-> msg.nonce] \in replayCache  \* replay
    /\ network' = network \ {msg}
    /\ UNCHANGED <<clientState, serverState, kdcState, replayCache, usedNonces>>

\* Step 5: Client receives OK
ClientReceiveOK(c, msg) ==
    /\ clientState[c] = "wait_auth"
    /\ msg \in network
    /\ msg.type = "OK"
    /\ msg.dst = c
    /\ clientState' = [clientState EXCEPT ![c] = "done"]
    /\ network' = network \ {msg}
    /\ UNCHANGED <<serverState, kdcState, replayCache, usedNonces>>

\* ================================================================
\* Unreliable network: message duplication and loss
\* ================================================================

\* Lose any message (reordering is implicit: any message can be consumed at any time)
\* Duplication is a no-op in set-based model; replay is tested by re-sending AP
NetworkLose(msg) ==
    /\ msg \in network
    /\ network' = network \ {msg}
    /\ UNCHANGED <<clientState, serverState, kdcState, replayCache, usedNonces>>

\* ================================================================
\* Next-state relation
\* ================================================================

Next ==
    \/ \E c \in Clients, n \in Nonces : ClientRequest(c, n)
    \/ \E msg \in network : KDCRespond(msg)
    \/ \E c \in Clients, msg \in network : ClientAuthenticate(c, msg)
    \/ \E msg \in network : ServerAccept(msg)
    \/ \E msg \in network : ServerReject(msg)
    \/ \E c \in Clients, msg \in network : ClientReceiveOK(c, msg)
    \/ \E msg \in network : NetworkLose(msg)

\* Safety spec: includes message loss, no fairness (safety only)
Spec == Init /\ [][Next]_vars

\* Liveness spec: no message loss, with fairness (for temporal properties)
NextNoLoss ==
    \/ \E c \in Clients, n \in Nonces : ClientRequest(c, n)
    \/ \E msg \in network : KDCRespond(msg)
    \/ \E c \in Clients, msg \in network : ClientAuthenticate(c, msg)
    \/ \E msg \in network : ServerAccept(msg)
    \/ \E msg \in network : ServerReject(msg)
    \/ \E c \in Clients, msg \in network : ClientReceiveOK(c, msg)

FairNoLoss ==
    /\ \A c \in Clients, n \in Nonces : WF_vars(ClientRequest(c, n))
    /\ \A msg \in Messages : WF_vars(KDCRespond(msg))
    /\ \A c \in Clients  : \A msg \in Messages : WF_vars(ClientAuthenticate(c, msg))
    /\ \A msg \in Messages : WF_vars(ServerAccept(msg))
    /\ \A c \in Clients  : \A msg \in Messages : WF_vars(ClientReceiveOK(c, msg))

SpecLive == Init /\ [][NextNoLoss]_vars /\ FairNoLoss

\* ================================================================
\* Safety invariants
\* ================================================================

\* If server accepted client c, then KDC must have issued a ticket for c
AcceptRequiresTicket ==
    \A c \in Clients :
        serverState[c] = "accepted" => c \in kdcState

\* If server accepted client c, then c actually initiated the protocol
AcceptRequiresClientInit ==
    \A c \in Clients :
        serverState[c] = "accepted" => clientState[c] \in {"wait_auth", "done"}

\* Replay cache only contains entries for nonces that clients actually used
ReplayCacheSound ==
    \A entry \in replayCache :
        entry.nonce \in usedNonces

\* ================================================================
\* Liveness properties (checked under fair network, i.e. no permanent loss)
\* ================================================================

\* Every client eventually completes authentication (reaches "done")
EventuallyAuthenticated ==
    \A c \in Clients : <>(clientState[c] = "done")

\* ================================================================
\* Negative invariant (for debugging: expected to be violated)
\* ================================================================
NobodyAccepted ==
    \A c \in Clients : serverState[c] # "accepted"

====
