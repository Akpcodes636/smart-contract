// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FreelanceEscrow.sol";

contract EscrowFactory {
    // =========================
    // STATE
    // =========================

    address public owner;
    address payable public platformWallet;
    uint256 public platformFeeBps; // e.g. 250 = 2.5%

    uint256 public constant MAX_FEE_BPS = 1000; // 10%

    FreelanceEscrow[] public escrows;

    // =========================
    // EVENTS
    // =========================

    event EscrowCreated(
        address indexed escrow,
        address indexed client,
        address indexed freelancer,
        uint256 price
    );

    event PlatformWalletUpdated(address indexed newWallet);
    event PlatformFeeUpdated(uint256 newFeeBps);

    // =========================
    // MODIFIERS
    // =========================

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // =========================
    // CONSTRUCTOR
    // =========================

    constructor(address payable _platformWallet, uint256 _feeBps) {
        require(_platformWallet != address(0), "Invalid wallet");
        require(_feeBps <= MAX_FEE_BPS, "Fee too high");

        owner = msg.sender;
        platformWallet = _platformWallet;
        platformFeeBps = _feeBps;
    }

    // =========================
    // ADMIN CONTROLS
    // =========================

    function updatePlatformWallet(address payable newWallet)
        external
        onlyOwner
    {
        require(newWallet != address(0), "Invalid wallet");
        platformWallet = newWallet;

        emit PlatformWalletUpdated(newWallet);
    }

    function updatePlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= MAX_FEE_BPS, "Too high");
        platformFeeBps = newFeeBps;

        emit PlatformFeeUpdated(newFeeBps);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }

    // =========================
    // CREATE ESCROW
    // =========================

    function createEscrow(
        address payable client,
        address payable freelancer,
        uint256 price,
        uint256 milestones,
        string calldata title,
        string calldata description
    ) external returns (address escrowAddress) {
        FreelanceEscrow escrow = new FreelanceEscrow(
            client,
            freelancer,
            price,
            milestones,
            title,
            description,
            platformWallet,
            platformFeeBps
        );

        escrows.push(escrow);

        emit EscrowCreated(
            address(escrow),
            client,
            freelancer,
            price
        );

        return address(escrow);
    }

    // =========================
    // VIEW HELPERS
    // =========================

    function totalEscrows() external view returns (uint256) {
        return escrows.length;
    }

    function getEscrow(uint256 index) external view returns (address) {
        return address(escrows[index]);
    }

    function getAllEscrows() external view returns (FreelanceEscrow[] memory) {
        return escrows;
    }
}
