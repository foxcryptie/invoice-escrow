# Threat model

This document describes the intended behavior of the educational `InvoiceEscrow` contract. It is not a security audit.

## Asset and roles

- **Asset:** the ETH deposited by the client when the contract is deployed.
- **Client:** deploys and funds the contract; can release the invoice amount to the contractor or refund it before release.
- **Contractor:** receives ETH if the client releases it; has no control over the contract.
- **Other addresses:** cannot change the state.

## Invariants

1. The contract starts in `Funded` with a nonzero amount and a distinct, nonzero contractor.
2. Only the client can move it to `Released` or `Refunded`.
3. Each terminal action pays exactly the original deposit amount and can succeed once.
4. State is set before the external ETH call. If the call fails, the transaction reverts, restoring both state and balance.

## Known limitations

- The client can refund even if the contractor has already done work. There is no approval deadline or dispute resolution.
- A contractor that cannot receive ETH can prevent release. The client may still refund while the contract remains `Funded`.
- ETH forced into the contract by another contract is not accounted for and cannot be recovered by this version.
- Contract behavior has not been independently reviewed. Do not deposit real funds.

## Test coverage

`test/InvoiceEscrow.t.sol` covers deployment constraints, both terminal paths, access control, repeated calls, failed payouts, and a fuzzed deposit/payout amount.
