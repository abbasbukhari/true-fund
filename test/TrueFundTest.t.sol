// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TrueFund} from "../src/TrueFund.sol";
import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";

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

    function testDonationToRecipient() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals)); // ETH/USD = $2000
        int256 ethUsdPrice = int256(2000 * 10 ** uint256(decimals)); // For minimum USD check

        // Deploy mock price feeds
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(
            decimals,
            ethUsdPrice
        );

        // Register recipient and add price feeds
        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed));
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed));

        // Set amountInLocalCurrency so donationInUsd >= MINIMUM_USD
        uint256 minUsd = trueFund.MINIMUM_USD();
        // Calculate required ETH for minimum USD
        uint256 ethAmount = (minUsd * 1e18) / uint256(ethUsdPrice); // scale up for decimals
        // Calculate local currency amount for that ETH
        uint256 amountInLocalCurrency = (ethAmount * uint256(price)) / 1e18;

        // Fund donor address with enough ETH
        vm.deal(address(3), ethAmount);

        // Logging for debug
        emit log_named_uint("ethAmount", ethAmount);
        emit log_named_uint("amountInLocalCurrency", amountInLocalCurrency);
        emit log_named_uint("MINIMUM_USD", minUsd);

        // Donate
        vm.prank(address(3)); // donor
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            amountInLocalCurrency
        );

        // Check recipient received ETH
        assertEq(recipient.balance, ethAmount);
    }

    function testDonationFailsForUnregisteredRecipient() public {
        address recipient = address(2);
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed));
        vm.prank(address(1));
        trueFund.addPriceFeed("USD", address(mockUsdFeed));

        uint256 minUsd = trueFund.MINIMUM_USD();
        uint256 ethAmount = (minUsd * 1e18) / uint256(price);
        uint256 amountInLocalCurrency = (ethAmount * uint256(price)) / 1e18;
        vm.deal(address(3), ethAmount);

        vm.prank(address(3));
        vm.expectRevert("Recipient not registered");
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            amountInLocalCurrency
        );
    }

    function testDonationFailsForUnsupportedCurrency() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "EUR"; // Not supported
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed));
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed));

        uint256 minUsd = trueFund.MINIMUM_USD();
        uint256 ethAmount = (minUsd * 1e18) / uint256(price);
        uint256 amountInLocalCurrency = (ethAmount * uint256(price)) / 1e18;
        vm.deal(address(3), ethAmount);

        vm.prank(address(3));
        vm.expectRevert("Currency not supported");
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            amountInLocalCurrency
        );
    }

    function testDonationFailsForMissingPriceFeed() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "CAD"; // Supported, but no price feed added
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed));
        // Do NOT add price feed for "CAD"

        uint256 minUsd = trueFund.MINIMUM_USD();
        uint256 ethAmount = (minUsd * 1e18) / uint256(price);
        uint256 amountInLocalCurrency = (ethAmount * uint256(price)) / 1e18;
        vm.deal(address(3), ethAmount);

        vm.prank(address(3));
        vm.expectRevert("Price feed not available");
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            amountInLocalCurrency
        );
    }

    function testDonationFailsForInsufficientETH() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed));
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed));

        uint256 minUsd = trueFund.MINIMUM_USD();
        uint256 ethAmount = (minUsd * 1e18) / uint256(price);
        uint256 amountInLocalCurrency = (ethAmount * uint256(price)) / 1e18;
        vm.deal(address(3), ethAmount - 1); // Not enough ETH

        vm.prank(address(3));
        vm.expectRevert("Insufficient ETH sent");
        trueFund.donationToRecipient{value: ethAmount - 1}(
            recipient,
            currency,
            amountInLocalCurrency
        );
    }

    function testDonationFailsForBelowMinimumUSD() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "CAD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed));
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed));

        uint256 minUsd = trueFund.MINIMUM_USD();
        uint256 ethAmount = (minUsd * 1e18) / uint256(price);
        vm.deal(address(3), ethAmount);

        // Set amountInLocalCurrency to a value that will result in donationInUsd < MINIMUM_USD
        uint256 lowAmount = 1 * 10 ** uint256(decimals); // $1 with 8 decimals, much less than minUsd

        vm.prank(address(3));
        vm.expectRevert("Donation must be at least 1 USD");
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            lowAmount
        );
    }

    function testAdminFunctionsFailForNonAdmin() public {
        address notAdmin = address(4);
        address recipient = address(2);
        string memory currency = "USD";
        address priceFeedAddress = address(5);

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.removeRecipientWithOrg(recipient);

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.addPriceFeed(currency, priceFeedAddress);

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.removePriceFeed(currency);
    }

    function testGetLatestPrice() public {
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(1234 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed));
        int256 fetchedPrice = trueFund.getLatestPrice(currency);
        assertEq(fetchedPrice, price);
    }

    function testGetRecipientOrgName() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    function testGetPriceFeedAddress() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress);
        address fetchedAddress = trueFund.getPriceFeedAddress(currency);
        assertEq(fetchedAddress, priceFeedAddress);
    }

    function testGetLatestPriceNonAdmin() public {
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(5678 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed));
        // Non-admin calls getter
        int256 fetchedPrice = trueFund.getLatestPrice(currency);
        assertEq(fetchedPrice, price);
    }

    function testGetRecipientOrgNameNonAdmin() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        // Non-admin calls getter
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    function testGetPriceFeedAddressNonAdmin() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress);
        // Non-admin calls getter
        address fetchedAddress = trueFund.getPriceFeedAddress(currency);
        assertEq(fetchedAddress, priceFeedAddress);
    }
}
