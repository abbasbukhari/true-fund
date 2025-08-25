// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TrueFund} from "../src/TrueFund.sol";

contract TrueFundTest is Test {
    TrueFund private trueFund;

    function setUp() public {
        vm.prank(address(1)); // Deploy contract as admin
        trueFund = new TrueFund();
    }

    // Add your test functions here
    function testRegisterRecipient() public {
        address recipient = address(2);
        vm.prank(address(1)); // simulate admin call
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    function testRemoveRecipient() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(address(1));
        trueFund.removeRecipientWithOrg(recipient);
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "");
    }

    function testAddPriceFeed() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress);
        address storedFeed = trueFund.getPriceFeedAddress(currency);
        assertEq(storedFeed, priceFeedAddress);
    }

    function testRemovePriceFeed() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress);
        vm.prank(address(1));
        trueFund.removePriceFeed(currency);
        address storedFeed = trueFund.getPriceFeedAddress(currency);
        assertEq(storedFeed, address(0));
    }
}
