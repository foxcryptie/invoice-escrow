// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title InvoiceEscrow
/// @notice A fixed-price, client-controlled ETH payment for one contractor.
/// @dev Educational example. The client can refund before release, so this does
///      not protect a contractor from an uncooperative client.
contract InvoiceEscrow {
    enum Status {
        Funded,
        Released,
        Refunded
    }

    error InvalidContractor();
    error InvalidAmount();
    error OnlyClient();
    error InvalidStatus();
    error TransferFailed();

    event Released(address indexed contractor, uint256 amount);
    event Refunded(address indexed client, uint256 amount);

    address public immutable client;
    address payable public immutable contractor;
    uint256 public immutable amount;
    Status public status;

    constructor(address payable contractor_) payable {
        if (contractor_ == address(0) || contractor_ == msg.sender) {
            revert InvalidContractor();
        }
        if (msg.value == 0) revert InvalidAmount();

        client = msg.sender;
        contractor = contractor_;
        amount = msg.value;
    }

    /// @notice Pay the contractor. Only the client may call this once.
    function release() external {
        if (msg.sender != client) revert OnlyClient();
        if (status != Status.Funded) revert InvalidStatus();

        status = Status.Released;
        emit Released(contractor, amount);
        (bool sent,) = contractor.call{value: amount}("");
        if (!sent) revert TransferFailed();
    }

    /// @notice Return the invoice amount to the client before release.
    function refund() external {
        if (msg.sender != client) revert OnlyClient();
        if (status != Status.Funded) revert InvalidStatus();

        status = Status.Refunded;
        emit Refunded(client, amount);
        (bool sent,) = payable(client).call{value: amount}("");
        if (!sent) revert TransferFailed();
    }
}
