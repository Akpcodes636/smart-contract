// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FreelanceEscrow.sol";

contract DeployEscrow is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address platformWallet = vm.envAddress("PLATFORM_WALLET");
        uint256 feeBps = vm.envUint("PLATFORM_FEE_BPS");

        vm.startBroadcast(deployerKey);

        new FreelanceEscrow(
            payable(0xClientAddress),
            payable(0xFreelancerAddress),
            10 ether,
            5,
            "Frontend Developer",
            "Build HR dashboard",
            payable(platformWallet),
            feeBps
        );

        vm.stopBroadcast();
    }
}
