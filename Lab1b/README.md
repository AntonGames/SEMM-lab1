# Lab1b: Abstract Specification, Refinement & Proof

## The Idea

In Lab1a, we modeled the Kerberos protocol with all its details — message exchanges between client, KDC, and server, ticket validation, replay cache lookups, and unreliable network behavior.

But at a higher abstraction level, the entire protocol achieves one thing: **a client transitions from unauthenticated to authenticated**. The abstract specification captures this essential behavior in a single atomic action, without any messages, tickets, or network.

The core question: **does the concrete multi-step protocol correctly implement this abstract one-step behavior?** This is **refinement** — showing that every behavior of the concrete system is a valid behavior of the abstract system.

## Two Abstraction Levels

- **Abstract** (`KerberosAbstract.tla`): One variable `authState[c] ∈ {idle, authenticated}`, one action `Authenticate(c)`. No messages, no KDC, no network.
- **Concrete** (`Kerberos.tla` from Lab1a): Six variables, seven actions, four message types, unreliable network with message loss.

Both specifications describe the same system at different levels of detail.

## How They Relate

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

The refinement mapping defines how concrete state variables map to abstract ones:

```
authState[c] == IF serverState[c] = "accepted" THEN "authenticated" ELSE "idle"
```

This single expression bridges the 6-variable concrete world to the 1-variable abstract world: a client is considered "authenticated" in the abstract sense precisely when the server has accepted them in the concrete protocol.

| Concrete (Lab1a) | Abstract (Lab1b) |
|---|---|
| `serverState[c] = "accepted"` | `authState[c] = "authenticated"` |
| `serverState[c] = "idle"` | `authState[c] = "idle"` |
| 6 variables, 7 actions, messages | 1 variable, 1 action, no messages |

TLC verifies refinement by running the concrete spec and checking, at every state, that the mapped abstract variables satisfy the abstract spec's transition relation.

## TLAPS Proofs

While TLC verifies properties for a finite model (e.g., 3 clients, 3 nonces), **TLAPS** provides a formal mathematical proof that holds for **arbitrary** constants. We prove two invariants:

### 1. TypeOK (type invariant)
All state variables stay within their declared domains throughout execution.

### 2. AcceptRequiresTicket (security invariant)
If `serverState[c] = "accepted"`, then `c ∈ kdcState`. The server never grants access to a client without a KDC-issued ticket.

### Proof technique

Both proofs use **inductive invariant reasoning**, decomposed per action:

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

The critical case is **ServerAccept** (step `<2>5`): it sets `serverState[c] = "accepted"` but only when `msg.src ∈ kdcState` — so the invariant is preserved by construction.

## Files

| File | Purpose |
|---|---|
| `KerberosAbstract.tla` | Abstract spec — one variable, one action |
| `KerberosAbstract.cfg` | TLC config for abstract spec |
| `KerberosRefinement.tla` | Refinement mapping + TLAPS proofs of TypeOK and AcceptRequiresTicket |
| `KerberosRefinement.cfg` | TLC config for refinement checking |
| `Kerberos.tla` | Copy of Lab1a's concrete spec (needed for INSTANCE import) |
