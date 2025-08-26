// SPDX-License-Identifier: MIT
// Foundry deployment script for TrueFund
pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {TrueFund} from "../src/TrueFund.sol";

contract DeployTrueFund is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        TrueFund trueFund = new TrueFund();
        vm.stopBroadcast();
    }
}
