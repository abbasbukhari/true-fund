// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TrueFund} from "../src/TrueFund.sol";

contract TrueFundTest is Test {
    TrueFund private trueFund;

    function setUp() public {
        trueFund = new TrueFund();
    }

    // Add your test functions here
}
