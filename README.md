# Invoice Escrow (Solidity + Foundry)

[![Foundry CI](https://github.com/foxcryptie/invoice-escrow/actions/workflows/ci.yml/badge.svg)](https://github.com/foxcryptie/invoice-escrow/actions/workflows/ci.yml)

A small, self-contained contract for a fixed-price invoice. The client funds it
on deployment, then either releases payment to the contractor or takes a
refund. I built it to practice state transitions, access control, ETH transfers,
and failure handling in Foundry.

This is a learning project, not an audited production escrow. Do not use it to
hold real funds.

## What I wanted to test

The contract has one active state, `Funded`, and two terminal states,
`Released` and `Refunded`. Neither terminal state can be entered twice. The
tests cover both paths, unauthorized calls, failed ETH transfers, invalid
deployments, and fuzzed deposit amounts.

## Run locally

Install [Foundry](https://getfoundry.sh/introduction/installation/), then run:

```bash
forge build
forge test -vv
```

No third-party Solidity libraries are required.

## Contract rules

- The client deploys the contract and supplies a nonzero ETH amount.
- The contractor is a distinct, nonzero address.
- Only the client can release payment or request a refund.
- State changes before ETH is sent. A failed transfer reverts the entire transaction.
- The contract emits an event for each successful terminal action.

## Security notes and limits

- This is **client-controlled**: the contractor cannot force payment. A real service would need a dispute process, a deadline, or an independent arbiter.
- Forced ETH can remain in the contract; actions transfer the original invoice amount, not the entire balance.
- The repository is a learning exercise. It has not been audited and should not be used to hold real funds.

## Layout

- `src/InvoiceEscrow.sol`: contract and custom errors
- `test/InvoiceEscrow.t.sol`: behavior and fuzz tests
- `foundry.toml`: compiler and test configuration
- `docs/THREAT_MODEL.md`: assumptions, invariants, and known limits

## If I extend it

A more realistic version would need a contractor-submission step, a review
deadline, and a clearly specified dispute mechanism. Those features are out of
scope here because they would change the trust model rather than simply add
convenience.

## License

MIT. See `LICENSE`.
