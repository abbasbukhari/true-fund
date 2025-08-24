// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title TrueFund
 * @author abbasbukhari
 * @notice Transparent, multi-currency donation contract for verified recipients.
 * @dev Donations are sent directly to recipient wallets, tracked on-chain with events. Admin can manage recipients and supported currencies.
 */

contract TrueFund {
    // --- Events ---
    // Emitted when a recipient is removed from the registry for transparency
    event RecipientRemoved(address indexed recipientAddress);
    // Emitted when a new price feed is added for a currency
    event PriceFeedAdded(string currency, address priceFeedAddress);
    // Emitted when a price feed is removed for a currency
    event PriceFeedRemoved(string currency);
    // Emitted when a donation is made to a recipient
    event DonationMade(
        address indexed donor,
        address indexed recipient,
        string currency,
        uint256 amount
    );

    // --- Constants ---
    // Minimum donation amount in USD (scaled to 18 decimals)
    uint256 public constant MINIMUM_USD = 1 * 10 ** 18;

    // The admin address that controls recipient and price feed management
    // Only this address can call admin-only functions
    // --- State Variables ---
    // The admin address that controls recipient and price feed management
    // Only this address can call admin-only functions
    address private i_admin;

    // Mapping from recipient address to organization name
    // Used to verify and lookup registered recipients
    // Mapping from recipient address to organization name
    // Used to verify and lookup registered recipients
    mapping(address => string) public recipientsAddressToOrgName;

    // Mapping from currency code (e.g., "USD", "CAD") to price feed contract address
    // Used to support multi-currency donations and conversions
    // Mapping from currency code (e.g., "USD", "CAD") to price feed contract address
    // Used to support multi-currency donations and conversions
    mapping(string => address) public priceFeeds;

    // --- Modifiers ---
    // Restrict function access to the admin only
    modifier onlyAdmin() {
        require(msg.sender == i_admin, "Only admin can perform this action");
        _;
    }

    // --- Constructor ---
    // Set the admin to the contract deployer
    constructor() {
        i_admin = msg.sender;
    }

    // --- Admin Functions ---
    /**
     * @notice Register a new recipient organization
     * @dev Only the admin can call this function
     * @param recipientAddress The wallet address of the organization or individual
     * @param recipientOrgName The name of the organization
     */
    function registerRecipientWithOrg(
        address recipientAddress,
        string memory recipientOrgName
    ) external onlyAdmin {
        recipientsAddressToOrgName[recipientAddress] = recipientOrgName;
    }

    /**
     * @notice Remove a recipient from the registry
     * @dev Only the admin can call this function
     * @param recipientAddress The wallet address of the recipient to remove
     */
    function removeRecipientWithOrg(
        address recipientAddress
    ) external onlyAdmin {
        delete recipientsAddressToOrgName[recipientAddress];
        emit RecipientRemoved(recipientAddress);
    }

    /**
     * @notice Add or update a price feed for a currency
     * @dev Only the admin can call this function
     * @param currency The currency code (e.g., "USD", "CAD")
     * @param priceFeedAddress The Chainlink price feed contract address
     */
    function addPriceFeed(
        string memory currency,
        address priceFeedAddress
    ) external onlyAdmin {
        priceFeeds[currency] = priceFeedAddress;
        emit PriceFeedAdded(currency, priceFeedAddress);
    }

    /**
     * @notice Remove a price feed for a currency
     * @dev Only the admin can call this function
     * @param currency The currency code to remove
     */
    function removePriceFeed(string memory currency) external onlyAdmin {
        delete priceFeeds[currency];
        emit PriceFeedRemoved(currency);
    }

    /**
     * @notice Donate to a registered recipient in a supported currency
     * @dev Converts local currency to ETH using Chainlink price feeds, enforces minimum USD value
     * @param recipientAddress The wallet address of the recipient
     * @param currencyCode The currency code (e.g., "USD", "CAD")
     * @param amountInLocalCurrency The donation amount in the local currency
     */
    function donationToRecipient(
        address recipientAddress,
        string memory currencyCode,
        uint256 amountInLocalCurrency
    ) external payable {
        // Ensure the recipient is registered
        require(
            bytes(recipientsAddressToOrgName[recipientAddress]).length != 0,
            "Recipient not registered"
        );

        // Supported currencies (hardcoded for now)
        require(
            keccak256(bytes(currencyCode)) == keccak256(bytes("USD")) ||
                keccak256(bytes(currencyCode)) == keccak256(bytes("CAD")) ||
                keccak256(bytes(currencyCode)) == keccak256(bytes("GBP")) ||
                keccak256(bytes(currencyCode)) == keccak256(bytes("HKD")) ||
                keccak256(bytes(currencyCode)) == keccak256(bytes("PKR")),
            "Currency not supported"
        );

        // Get the price feed address for the currency
        address priceFeedAddress = priceFeeds[currencyCode];
        require(priceFeedAddress != address(0), "Price feed not available");

        // Get the latest price from Chainlink
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed data");

        // Convert local currency amount to ETH
        uint256 ethAmount = (uint256(amountInLocalCurrency) * 1e18) /
            uint256(price);

        // Get ETH/USD price feed for minimum USD check
        address usdPriceFeedAddress = priceFeeds["USD"];
        require(
            usdPriceFeedAddress != address(0),
            "USD price feed not available"
        );
        AggregatorV3Interface usdPriceFeed = AggregatorV3Interface(
            usdPriceFeedAddress
        );
        (, int256 ethUsdPrice, , , ) = usdPriceFeed.latestRoundData();
        require(ethUsdPrice > 0, "Invalid USD price feed data");
        uint256 donationInUsd = (ethAmount * uint256(ethUsdPrice)) / 1e18;
        require(
            donationInUsd >= MINIMUM_USD,
            "Donation must be at least 1 USD"
        );

        // Require enough ETH sent
        require(msg.value >= ethAmount, "Insufficient ETH sent");

        // Transfer ETH to recipient
        (bool sent, ) = recipientAddress.call{value: ethAmount}("");
        require(sent, "ETH transfer failed");

        // Emit donation event
        emit DonationMade(
            msg.sender,
            recipientAddress,
            currencyCode,
            amountInLocalCurrency
        );
    }

    // --- View/Helper Functions ---
    /**
     * @notice Get the latest price from a Chainlink price feed for a given currency code
     * @param currencyCode The currency code (e.g., "USD", "CAD")
     * @return price The latest price from the feed
     */
    function getLatestPrice(
        string memory currencyCode
    ) public view returns (int256) {
        address priceFeedAddress = priceFeeds[currencyCode];
        require(priceFeedAddress != address(0), "Price feed not available");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getRecipientOrgName(
        address recipientAddress
    ) public view returns (string memory orgName) {
        orgName = recipientsAddressToOrgName[recipientAddress];
    }

    function getPriceFeedAddress(
        string memory currencyCode
    ) public view returns (address feedAddress) {
        feedAddress = priceFeeds[currencyCode];
    }
}
