// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Escrow {
    // =========================
    // Custom errors
    // =========================
    error AlreadyStaked();
    error FundsNotStaked();
    error AllMilestonesPaid();
    error CancellationRequested();

    // =========================
    // State
    // =========================
    enum ProjectState {
        None,            // 0: unused
        Active,          // 1: default active
        CancelRequested, // 2: one party requested cancel
        Cancelled,       // 3: both requested cancel
        Completed        // 4
    }

    struct ContractStatus {
        address client;
        address freelancer;
        uint256 projectPrice;
        string title;
        string description;
        bool clientStaked;
        bool clientCancel;
        bool freelancerCancel;
        ProjectState projectState;
        uint256 numberOfMilestones;
        uint256 completedMilestones;
        address platformWallet;
        uint256 platformFeeBps;
    }

    address payable public client;
    address payable public freelancer;
    uint256 public projectPrice;
    string public title;
    string public description;

    bool public clientStaked;
    bool public clientCancel;
    bool public freelancerCancel;
    ProjectState public projectState;
    uint256 public numberOfMilestones;
    uint256 public completedMilestones;
    address payable public platformWallet;
    uint256 public platformFeeBps;

    // =========================
    // Constructor
    // =========================
    constructor(
        address payable _client,
        address payable _freelancer,
        uint256 _projectPrice,
        uint256 _numberOfMilestones,
        string memory _title,
        string memory _description,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) {
        client = _client;
        freelancer = _freelancer;
        projectPrice = _projectPrice;
        numberOfMilestones = _numberOfMilestones;
        title = _title;
        description = _description;
        platformWallet = _platformWallet;
        platformFeeBps = _platformFeeBps;

        projectState = ProjectState.Active;
    }

    // =========================
    // Actions
    // =========================
    function stake() external payable {
        if (clientStaked) revert AlreadyStaked();
        require(msg.sender == client, "Only client can stake");
        require(msg.value == projectPrice, "Incorrect stake amount");
        clientStaked = true;
    }

    function payByMilestone() external {
        if (!clientStaked) revert FundsNotStaked();
        if (projectState == ProjectState.CancelRequested || projectState == ProjectState.Cancelled) {
            revert CancellationRequested();
        }
        if (completedMilestones >= numberOfMilestones) revert AllMilestonesPaid();

        uint256 payout = (projectPrice / numberOfMilestones) * (10000 - platformFeeBps) / 10000;
        uint256 platformFee = (projectPrice / numberOfMilestones) - payout;

        completedMilestones++;

        _payout(freelancer, payout, platformFee);

        if (completedMilestones == numberOfMilestones) {
            projectState = ProjectState.Completed;
        }
    }

    function payAtOnce() external {
        if (!clientStaked) revert FundsNotStaked();
        if (projectState == ProjectState.CancelRequested || projectState == ProjectState.Cancelled) {
            revert CancellationRequested();
        }

        uint256 platformFee = (projectPrice * platformFeeBps) / 10000;
        uint256 payout = projectPrice - platformFee;

        completedMilestones = numberOfMilestones;
        projectState = ProjectState.Completed;

        _payout(freelancer, payout, platformFee);
    }

    function requestCancel() external {
        require(msg.sender == client || msg.sender == freelancer, "Invalid sender");

        if (msg.sender == client) clientCancel = true;
        else freelancerCancel = true;

        if (clientCancel && freelancerCancel) {
            projectState = ProjectState.Cancelled;
        } else if (clientCancel || freelancerCancel) {
            projectState = ProjectState.CancelRequested;
        }
    }

    function revokeCancel() external {
        require(msg.sender == client || msg.sender == freelancer, "Invalid sender");

        if (msg.sender == client) clientCancel = false;
        else freelancerCancel = false;

        if (!clientCancel && !freelancerCancel) {
            projectState = ProjectState.Active;
        }
    }

    // =========================
    // View
    // =========================
    function getStatus() external view returns (ContractStatus memory) {
        return ContractStatus({
            client: client,
            freelancer: freelancer,
            projectPrice: projectPrice,
            title: title,
            description: description,
            clientStaked: clientStaked,
            clientCancel: clientCancel,
            freelancerCancel: freelancerCancel,
            projectState: projectState,
            numberOfMilestones: numberOfMilestones,
            completedMilestones: completedMilestones,
            platformWallet: platformWallet,
            platformFeeBps: platformFeeBps
        });
    }

    // =========================
    // Internal
    // =========================
    function _payout(address payable _freelancer, uint256 _payout, uint256 _platformFee) internal {
        (bool sent1, ) = _freelancer.call{value: _payout}("");
        require(sent1, "Payout failed");

        (bool sent2, ) = platformWallet.call{value: _platformFee}("");
        require(sent2, "Platform fee failed");
    }

    // =========================
    // Receive
    // =========================
    receive() external payable {}
}
