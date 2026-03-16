# Lab1b: Abstraction, Refinement & TLAPS Proofs

## Overview

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryTextColor': '#000000', 'nodeTextColor': '#000000', 'clusterBkg': '#e3f2fd', 'clusterBorder': '#1565c0'}}}%%
flowchart TB
    subgraph Abstract["Lab1b: KerberosAbstract (high-level)"]
        direction LR
        A_idle["authState[c] = idle"] -->|"Authenticate(c)<br/>(single atomic step)"| A_auth["authState[c] = authenticated"]
    end

    subgraph Concrete["Lab1a: Kerberos (concrete protocol)"]
        direction LR
        C_idle["clientState = idle<br/>serverState = idle"] -->|"ClientRequest"| C_wait["clientState = wait_ticket"]
        C_wait -->|"KDCRespond + ClientAuthenticate"| C_auth["clientState = wait_auth"]
        C_auth -->|"ServerAccept + ClientReceiveOK"| C_done["clientState = done<br/>serverState = accepted"]
    end

    subgraph Mapping["Refinement Mapping"]
        direction LR
        M["authState[c] =<br/>IF serverState[c] = accepted<br/>THEN authenticated<br/>ELSE idle"]
    end

    subgraph Proofs["TLAPS Proofs"]
        direction TB
        P1["THEOREM TypeInvariant<br/>Spec ⟹ □TypeOK"]
        P2["THEOREM Safety<br/>Spec ⟹ □AcceptRequiresTicket"]
        P1 --- P2
    end

    Concrete -->|"refines"| Abstract
    Mapping -->|"connects"| Abstract
    Mapping -->|"maps from"| Concrete
    Proofs -->|"proved for"| Concrete
```

## Refinement Mapping

The concrete Kerberos protocol (with messages, KDC, replay cache) **refines** the abstract specification where authentication is a single atomic step:

| Concrete (Lab1a) | Abstract (Lab1b) |
|---|---|
| `serverState[c] = "accepted"` | `authState[c] = "authenticated"` |
| `serverState[c] = "idle"` | `authState[c] = "idle"` |
| 6 variables, 7 actions, messages | 1 variable, 1 action, no messages |

## TLAPS Proof Structure

Both proofs follow the standard inductive invariant pattern, decomposed per action:

```
THEOREM: Spec ⟹ □Invariant
  <1>1. Init ⟹ Invariant                    (base case)
  <1>2. Invariant ∧ [Next]_vars ⟹ Invariant' (inductive step)
    <2>2. CASE ClientRequest      — preserves invariant
    <2>3. CASE KDCRespond         — preserves invariant
    <2>4. CASE ClientAuthenticate — preserves invariant
    <2>5. CASE ServerAccept       — KEY: src ∈ kdcState precondition
    <2>6. CASE ServerReject       — no state change
    <2>7. CASE ClientReceiveOK    — preserves invariant
    <2>8. CASE NetworkLose        — preserves invariant
    <2>9. CASE UNCHANGED vars     — stutter step
  <1>q. QED BY <1>1, <1>2, PTL
```
