# Invoice Escrow (Solidity + Foundry)

> **Status: private learning draft.** I used AI assistance for the first version
> and have not completed my own security review yet. I am keeping it private
> until I can explain and verify the full design. Do not deploy it with real
> funds.

A small, self-contained contract for a fixed-price invoice. The client funds it on deployment, then either releases payment to the contractor or takes a refund. It is an educational draft, not an audited production escrow.

## Why this project

The repository is designed to show a clear state machine, access control, ETH transfer handling, tests, and a short security review. The two terminal states are `Released` and `Refunded`; neither can be entered twice.

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

## Next steps

Add a contractor-submission step, a review deadline, and a clearly specified dispute mechanism before considering real-world use.

## License

MIT. See `LICENSE`.
