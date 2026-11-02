// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {InvoiceEscrow} from "../src/InvoiceEscrow.sol";

interface Vm {
    function deal(address account, uint256 newBalance) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function expectRevert(bytes4 selector) external;
}

contract RejectEther {
    receive() external payable {
        revert("no ETH");
    }
}

contract InvoiceEscrowTest {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address payable private constant CONTRACTOR = payable(address(0xBEEF));
    address private constant OUTSIDER = address(0xCAFE);
    uint256 private constant PRICE = 1 ether;

    InvoiceEscrow private escrow;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        escrow = new InvoiceEscrow{value: PRICE}(CONTRACTOR);
    }

    function testStartsFunded() public view {
        require(escrow.client() == address(this), "wrong client");
        require(escrow.contractor() == CONTRACTOR, "wrong contractor");
        require(escrow.amount() == PRICE, "wrong amount");
        require(
            escrow.status() == InvoiceEscrow.Status.Funded,
            "wrong initial state"
        );
        require(address(escrow).balance == PRICE, "wrong balance");
    }

    function testReleasePaysContractorOnce() public {
        uint256 beforeBalance = CONTRACTOR.balance;
        escrow.release();
        require(CONTRACTOR.balance == beforeBalance + PRICE, "not paid");
        require(
            escrow.status() == InvoiceEscrow.Status.Released,
            "not released"
        );
        require(address(escrow).balance == 0, "balance not cleared");

        vm.expectRevert(InvoiceEscrow.InvalidStatus.selector);
        escrow.release();
        vm.expectRevert(InvoiceEscrow.InvalidStatus.selector);
        escrow.refund();
    }

    function testRefundPaysClientOnce() public {
        uint256 beforeBalance = address(this).balance;
        escrow.refund();
        require(address(this).balance == beforeBalance + PRICE, "not refunded");
        require(
            escrow.status() == InvoiceEscrow.Status.Refunded,
            "not refunded state"
        );
        require(address(escrow).balance == 0, "balance not cleared");

        vm.expectRevert(InvoiceEscrow.InvalidStatus.selector);
        escrow.refund();
        vm.expectRevert(InvoiceEscrow.InvalidStatus.selector);
        escrow.release();
    }

    function testOnlyClientCanReleaseOrRefund() public {
        vm.startPrank(OUTSIDER);
        vm.expectRevert(InvoiceEscrow.OnlyClient.selector);
        escrow.release();
        vm.expectRevert(InvoiceEscrow.OnlyClient.selector);
        escrow.refund();
        vm.stopPrank();
    }

    function testRejectsInvalidDeployment() public {
        vm.expectRevert(InvoiceEscrow.InvalidContractor.selector);
        new InvoiceEscrow{value: PRICE}(payable(address(0)));

        vm.expectRevert(InvoiceEscrow.InvalidContractor.selector);
        new InvoiceEscrow{value: PRICE}(payable(address(this)));

        vm.expectRevert(InvoiceEscrow.InvalidAmount.selector);
        new InvoiceEscrow(CONTRACTOR);
    }

    function testRevertingPayoutKeepsFundsAndState() public {
        RejectEther receiver = new RejectEther();
        InvoiceEscrow another =
            new InvoiceEscrow{value: PRICE}(payable(address(receiver)));

        vm.expectRevert(InvoiceEscrow.TransferFailed.selector);
        another.release();
        require(
            another.status() == InvoiceEscrow.Status.Funded,
            "state changed on revert"
        );
        require(address(another).balance == PRICE, "funds lost on revert");
    }

    function testFuzz_PayoutMatchesDeposit(uint96 rawAmount) public {
        uint256 deposit = uint256(rawAmount) + 1;
        vm.deal(address(this), deposit);
        InvoiceEscrow another =
            new InvoiceEscrow{value: deposit}(CONTRACTOR);
        uint256 beforeBalance = CONTRACTOR.balance;

        another.release();
        require(
            CONTRACTOR.balance == beforeBalance + deposit,
            "wrong payout"
        );
    }

    receive() external payable {}
}
