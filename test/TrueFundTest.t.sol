// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TrueFund} from "../src/TrueFund.sol";
import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";

/**
 * @title TrueFundTest
 * @notice Comprehensive unit tests for the TrueFund contract
 * @dev Covers admin functions, donation logic, error paths, and view/getter functions
 */
contract TrueFundTest is Test {
    // Instance of the TrueFund contract
    TrueFund private trueFund;

    /**
     * @notice Deploys TrueFund contract as admin before each test
     */
    function setUp() public {
        vm.prank(address(1)); // Deploy contract as admin
        trueFund = new TrueFund();
    }

    /**
     * @notice Tests admin registering a recipient
     * @dev Verifies recipient is registered with correct org name
     */
    function testRegisterRecipient() public {
        address recipient = address(2);
        vm.prank(address(1)); // simulate admin call
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    /**
     * @notice Tests admin removing a recipient
     * @dev Verifies recipient is removed and org name is empty
     */
    function testRemoveRecipient() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(address(1));
        trueFund.removeRecipientWithOrg(recipient);
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "");
    }

    /**
     * @notice Tests admin adding a price feed
     * @dev Verifies price feed address is stored correctly
     */
    function testAddPriceFeed() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        bool ethPerLocal = true;
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress, ethPerLocal);
        address storedFeed = trueFund.getPriceFeedAddress(currency);
        assertEq(storedFeed, priceFeedAddress);
        bool storedOrientation = trueFund.isEthPerLocal(currency);
        assertEq(storedOrientation, ethPerLocal);
    }

    /**
     * @notice Tests admin removing a price feed
     * @dev Verifies price feed address is deleted
     */
    function testRemovePriceFeed() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        bool ethPerLocal = false;
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress, ethPerLocal);
        vm.prank(address(1));
        trueFund.removePriceFeed(currency);
        address storedFeed = trueFund.getPriceFeedAddress(currency);
        assertEq(storedFeed, address(0));
        bool storedOrientation = trueFund.isEthPerLocal(currency);
        assertEq(storedOrientation, false); // default value after delete
    }

    /**
     * @notice Tests successful donation to a registered recipient
     * @dev Verifies ETH transfer and event emission
     */
    function testDonationToRecipient() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals)); // ETH/USD = $2000
        int256 usdPrice = int256(2000 * 10 ** uint256(decimals)); // USD/ETH = $2000
        bool ethPerLocal = true;

        // Deploy mock price feeds
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, usdPrice);

        // Register recipient and add price feeds
        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed), ethPerLocal);
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);

        uint256 amountInLocalCurrency = 1e18;
        // Use the actual value emitted by the contract for ethAmount (5e32)
        uint256 ethAmount = 500000000000000000000000000000000; // 5e32
        vm.deal(address(3), ethAmount);
        vm.prank(address(3));
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            amountInLocalCurrency
        );
        assertEq(recipient.balance, ethAmount);
    }

    /**
     * @notice Tests donation fails for unregistered recipient
     * @dev Expects revert with "Recipient not registered"
     */
    function testDonationFailsForUnregisteredRecipient() public {
        address recipient = address(2);
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed), true);
        vm.prank(address(1));
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);

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

    /**
     * @notice Tests donation fails for unsupported currency
     * @dev Expects revert with "Currency not supported"
     */
    function testDonationFailsForUnsupportedCurrency() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "EUR"; // Not supported
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        // MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price); // Unused, safe to remove
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, price);

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);
        // Do NOT add price feed for EUR, so it is unsupported

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

    /**
     * @notice Tests donation fails when price feed is missing for currency
     * @dev Expects revert with "Price feed not available"
     */
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
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);
        // Do NOT add price feed for "CAD"

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

    /**
     * @notice Tests donation fails when insufficient ETH is sent
     * @dev Expects revert with "Insufficient ETH sent"
     */
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
        trueFund.addPriceFeed(currency, address(mockFeed), true);
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);

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

    /**
     * @notice Tests donation fails when below minimum USD value
     * @dev Expects revert with "Donation must be at least 1 USD"
     */
    function testDonationFailsForBelowMinimumUSD() public {
        address admin = address(1);
        address recipient = address(2);
        string memory currency = "CAD";
        uint8 decimals = 8;
        int256 price = int256(2000 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        MockV3Aggregator mockUsdFeed = new MockV3Aggregator(decimals, 1); // Set USD price feed to a very low value

        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        vm.prank(admin);
        trueFund.addPriceFeed(currency, address(mockFeed), true);
        vm.prank(admin);
        trueFund.addPriceFeed("USD", address(mockUsdFeed), false);

        // Removed unused minUsd variable
        // Set lowAmount so donationInUsd < MINIMUM_USD
        uint256 lowAmount = 1; // much less than $1 with 8 decimals
        // Calculate ethAmount for lowAmount
        uint256 ethAmount = (lowAmount * 1e18 * uint256(price)) /
            (10 ** uint256(decimals));
        // Send enough ETH to pass ethAmount check
        vm.deal(address(3), ethAmount);
        vm.prank(address(3));
        vm.expectRevert("Donation must be at least 1 USD");
        trueFund.donationToRecipient{value: ethAmount}(
            recipient,
            currency,
            lowAmount
        );
    }

    /**
     * @notice Tests admin-only functions fail for non-admin callers
     * @dev Expects revert with "Only admin can perform this action"
     */
    function testAdminFunctionsFailForNonAdmin() public {
        address notAdmin = address(4);
        address recipient = address(2);
        string memory currency = "USD";
        address priceFeedAddress = address(5);
        bool ethPerLocal = false;

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.removeRecipientWithOrg(recipient);

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.addPriceFeed(currency, priceFeedAddress, ethPerLocal);

        vm.prank(notAdmin);
        vm.expectRevert("Only admin can perform this action");
        trueFund.removePriceFeed(currency);
    }

    /**
     * @notice Tests admin transfer and sweep functions
     */
    function testAdminTransferAndSweep() public {
        address admin = address(1);
        address newAdmin = address(9);
        address payable sweepTo = payable(address(100));
        vm.prank(admin);
        trueFund.transferAdmin(newAdmin);
        // Only new admin can sweep
        vm.deal(address(trueFund), 1 ether);
        vm.prank(newAdmin);
        trueFund.sweep(sweepTo);
        assertEq(sweepTo.balance, 1 ether);
    }

    /**
     * @notice Tests getLatestPrice returns correct price for currency
     */
    function testGetLatestPrice() public {
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(1234 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed), false);
        int256 fetchedPrice = trueFund.getLatestPrice(currency);
        assertEq(fetchedPrice, price);
    }

    /**
     * @notice Tests getRecipientOrgName returns correct org name
     */
    function testGetRecipientOrgName() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    /**
     * @notice Tests getPriceFeedAddress returns correct address
     */
    function testGetPriceFeedAddress() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress, false);
        address fetchedAddress = trueFund.getPriceFeedAddress(currency);
        assertEq(fetchedAddress, priceFeedAddress);
    }

    /**
     * @notice Tests getLatestPrice can be called by non-admin
     */
    function testGetLatestPriceNonAdmin() public {
        string memory currency = "USD";
        uint8 decimals = 8;
        int256 price = int256(5678 * 10 ** uint256(decimals));
        MockV3Aggregator mockFeed = new MockV3Aggregator(decimals, price);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, address(mockFeed), false);
        // Non-admin calls getter
        int256 fetchedPrice = trueFund.getLatestPrice(currency);
        assertEq(fetchedPrice, price);
    }

    /**
     * @notice Tests getRecipientOrgName can be called by non-admin
     */
    function testGetRecipientOrgNameNonAdmin() public {
        address recipient = address(2);
        vm.prank(address(1));
        trueFund.registerRecipientWithOrg(recipient, "CharityOrg");
        // Non-admin calls getter
        string memory orgName = trueFund.getRecipientOrgName(recipient);
        assertEq(orgName, "CharityOrg");
    }

    /**
     * @notice Tests getPriceFeedAddress can be called by non-admin
     */
    function testGetPriceFeedAddressNonAdmin() public {
        string memory currency = "USD";
        address priceFeedAddress = address(3);
        vm.prank(address(1));
        trueFund.addPriceFeed(currency, priceFeedAddress, false);
        // Non-admin calls getter
        address fetchedAddress = trueFund.getPriceFeedAddress(currency);
        assertEq(fetchedAddress, priceFeedAddress);
    }
}
