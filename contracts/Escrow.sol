// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract FreelanceEscrow {
    // =========================
    // ENUMS & STRUCTS
    // =========================

    enum ProjectState {
        Initiated,
        Active,
        Cancelled,
        Completed
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
        address agreementAddress;
        address platformWallet;
        uint256 platformFeeBps;
    }

    // =========================
    // STATE VARIABLES
    // =========================

    address payable private client;
    address payable private freelancer;

    address payable public platformWallet;
    uint256 public platformFeeBps; // e.g. 200 = 2%

    uint256 private projectPrice;
    uint256 private numberOfMilestones;
    uint256 private completedMilestones;
    uint256 private milestonePayment;

    string private title;
    string private description;

    ProjectState public projectState;

    mapping(address => bool) private stakeStatus;
    mapping(address => bool) private cancelStatus;

    uint256 constant MAX_FEE_BPS = 1000; // max 10%

    // =========================
    // EVENTS
    // =========================

    event AgreementStateChanged(
        address indexed client,
        address indexed freelancer,
        ContractStatus status
    );

    event PlatformPaid(address indexed wallet, uint256 amount);

    // =========================
    // MODIFIERS
    // =========================

    modifier onlyClient() {
        require(msg.sender == client, "Only client allowed");
        _;
    }

    modifier onlyClientOrFreelancer() {
        require(
            msg.sender == client || msg.sender == freelancer,
            "Not authorized"
        );
        _;
    }

    modifier inState(ProjectState state) {
        require(projectState == state, "Invalid project state");
        _;
    }

    modifier escrowLocked() {
        require(stakeStatus[client], "Funds not staked");
        _;
    }

    // =========================
    // CONSTRUCTOR
    // =========================

    constructor(
        address payable _client,
        address payable _freelancer,
        uint256 _price,
        uint256 _milestones,
        string memory _title,
        string memory _description,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) {
        require(_client != _freelancer, "Client and freelancer must differ");
        require(_price > 0, "Invalid price");
        require(_milestones > 0, "Invalid milestone count");
        require(_platformWallet != address(0), "Invalid platform wallet");
        require(_platformFeeBps <= MAX_FEE_BPS, "Fee too high");

        client = _client;
        freelancer = _freelancer;
        projectPrice = _price;
        numberOfMilestones = _milestones;
        milestonePayment = _price / _milestones;

        title = _title;
        description = _description;

        platformWallet = _platformWallet;
        platformFeeBps = _platformFeeBps;

        projectState = ProjectState.Initiated;
    }

    // =========================
    // CORE FUNCTIONS
    // =========================

    function stake() external payable onlyClient inState(ProjectState.Initiated) {
        require(!stakeStatus[client], "Already staked");
        require(msg.value == projectPrice, "Incorrect amount");

        stakeStatus[client] = true;
        projectState = ProjectState.Active;

        emit AgreementStateChanged(client, freelancer, getStatus());
    }

    function payByMilestone()
        external
        onlyClient
        inState(ProjectState.Active)
        escrowLocked
    {
        require(completedMilestones < numberOfMilestones, "All milestones paid");
        require(
            !cancelStatus[client] && !cancelStatus[freelancer],
            "Cancellation requested"
        );

        completedMilestones++;

        uint256 amount = milestonePayment;

        if (completedMilestones == numberOfMilestones) {
            projectState = ProjectState.Completed;
            amount = address(this).balance;
        }

        _payout(amount);

        emit AgreementStateChanged(client, freelancer, getStatus());
    }

    function payAtOnce()
        external
        onlyClient
        inState(ProjectState.Active)
        escrowLocked
    {
        projectState = ProjectState.Completed;

        uint256 balance = address(this).balance;

        _payout(balance);

        emit AgreementStateChanged(client, freelancer, getStatus());
    }

    // =========================
    // INTERNAL PAYOUT
    // =========================

    function _payout(uint256 grossAmount) internal {
        uint256 fee = (grossAmount * platformFeeBps) / 10_000;
        uint256 freelancerAmount = grossAmount - fee;

        if (fee > 0) {
            (bool feeSent, ) = platformWallet.call{value: fee}("");
            require(feeSent, "Platform fee transfer failed");

            emit PlatformPaid(platformWallet, fee);
        }

        (bool success, ) = freelancer.call{value: freelancerAmount}("");
        require(success, "Freelancer transfer failed");
    }

    // =========================
    // CANCELLATION
    // =========================

    function requestCancel()
        external
        onlyClientOrFreelancer
        inState(ProjectState.Active)
        escrowLocked
    {
        cancelStatus[msg.sender] = true;

        if (cancelStatus[client] && cancelStatus[freelancer]) {
            projectState = ProjectState.Cancelled;

            uint256 balance = address(this).balance;

            (bool success, ) = client.call{value: balance}("");
            require(success, "Refund failed");
        }

        emit AgreementStateChanged(client, freelancer, getStatus());
    }

    function revokeCancel()
        external
        onlyClientOrFreelancer
        inState(ProjectState.Active)
    {
        cancelStatus[msg.sender] = false;

        emit AgreementStateChanged(client, freelancer, getStatus());
    }

    // =========================
    // VIEW
    // =========================

    function getStatus() public view returns (ContractStatus memory) {
        return ContractStatus(
            client,
            freelancer,
            projectPrice,
            title,
            description,
            stakeStatus[client],
            cancelStatus[client],
            cancelStatus[freelancer],
            projectState,
            numberOfMilestones,
            completedMilestones,
            address(this),
            platformWallet,
            platformFeeBps
        );
    }
}
