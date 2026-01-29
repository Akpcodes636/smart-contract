// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../contracts/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address client = address(0x1);
    address freelancer = address(0x2);
    address platformWallet = address(0x3);
    uint256 price = 1 ether;
    uint256 milestones = 2;

    function setUp() public {
        // Fund test addresses
        vm.deal(client, 10 ether);
        vm.deal(freelancer, 10 ether);
        vm.deal(platformWallet, 10 ether);

        // Deploy Escrow contract
        escrow = new Escrow(
            payable(client),
            payable(freelancer),
            price,
            milestones,
            "Test Project",
            "Testing Escrow",
            payable(platformWallet),
            300
        );
    }

    // =========================
    // Base functionality tests
    // =========================

    function testClientCanStake() public {
        vm.prank(client);
        escrow.stake{value: price}();

        Escrow.ContractStatus memory status = escrow.getStatus();
        assertTrue(status.clientStaked, "Client should have staked funds");
    }

    function testPayByMilestone() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        escrow.payByMilestone();

        Escrow.ContractStatus memory status = escrow.getStatus();
        assertEq(status.completedMilestones, 1, "Completed milestones should be 1");
    }

    function testFullPaymentCompletesProject() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        escrow.payAtOnce();

        Escrow.ContractStatus memory status = escrow.getStatus();
        assertEq(uint256(status.projectState), 4, "Project state should be Completed");
    }

    // =========================
    // Edge-case tests
    // =========================

    function testCannotStakeTwice() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        vm.expectRevert(Escrow.AlreadyStaked.selector);
        escrow.stake{value: price}();
    }

    function testCannotPayMilestoneWithoutStaking() public {
        vm.prank(client);
        vm.expectRevert(Escrow.FundsNotStaked.selector);
        escrow.payByMilestone();
    }

    function testCancelFlow() public {
        vm.prank(client);
        escrow.stake{value: price}();

        // Client requests cancel
        vm.prank(client);
        escrow.requestCancel();
        Escrow.ContractStatus memory status1 = escrow.getStatus();
        assertTrue(status1.clientCancel, "Client cancel should be true");
        assertEq(uint256(status1.projectState), 2, "Project should be CancelRequested");

        // Freelancer requests cancel
        vm.prank(freelancer);
        escrow.requestCancel();
        Escrow.ContractStatus memory status2 = escrow.getStatus();
        assertEq(uint256(status2.projectState), 3, "Project should be Cancelled");
    }

    function testRevokeCancel() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        escrow.requestCancel();

        vm.prank(client);
        escrow.revokeCancel();

        Escrow.ContractStatus memory status = escrow.getStatus();
        assertFalse(status.clientCancel, "Client cancel should be false after revoke");
        assertEq(uint256(status.projectState), 1, "Project should remain Active");
    }

    function testCannotPayAfterCancelRequested() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        escrow.requestCancel();

        vm.prank(freelancer);
        escrow.requestCancel();

        vm.prank(client);
        vm.expectRevert(Escrow.CancellationRequested.selector);
        escrow.payByMilestone();
    }

    function testCannotOverpayMilestones() public {
        vm.prank(client);
        escrow.stake{value: price}();

        vm.prank(client);
        escrow.payByMilestone();

        vm.prank(client);
        escrow.payByMilestone(); // all milestones paid

        vm.prank(client);
        vm.expectRevert(Escrow.AllMilestonesPaid.selector);
        escrow.payByMilestone(); // extra payment → should fail
    }
}

