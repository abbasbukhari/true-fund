// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import {PriceUtils} from "./PriceUtils.sol";

/**
 * @title TrueFund
 * @author abbasbukhari
 * @notice Transparent, multi-currency donation contract for verified recipients.
 * @dev Donations are sent directly to recipient wallets, tracked on-chain with events. Admin can manage recipients and supported currencies.
 */

contract TrueFund {
    // Price helper functions moved to PriceUtils library

    // --- Events ---
    event RecipientRemoved(address indexed recipientAddress);
    event PriceFeedAdded(
        string currency,
        address priceFeedAddress,
        bool isEthPerLocal
    );
    event PriceFeedRemoved(string currency);
    event DonationMade(
        address indexed donor,
        address indexed recipient,
        string currency,
        uint256 localAmount,
        uint256 ethAmount,
        uint256 usdAmount
    );

    // --- Constants ---
    // Minimum donation amount in USD (scaled to 18 decimals)
    uint256 public constant MINIMUM_USD = 1 * 10 ** 18;

    // --- State Variables ---
    address private i_admin;
    mapping(address => string) public recipientsAddressToOrgName;

    // Mapping to track refunds for donors
    mapping(address => uint256) public refund;
    // Mapping from currency code (e.g., "USD", "CAD") to price feed contract address
    mapping(string => address) public priceFeeds;
    // Mapping from currency code to feed orientation (true = ETH per LOCAL, false = LOCAL per ETH)
    mapping(string => bool) public isEthPerLocal;

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
        address priceFeedAddress,
        bool ethPerLocal
    ) external onlyAdmin {
        priceFeeds[currency] = priceFeedAddress;
        isEthPerLocal[currency] = ethPerLocal;
        emit PriceFeedAdded(currency, priceFeedAddress, ethPerLocal);
    }

    /**
     * @notice Remove a price feed for a currency
     * @dev Only the admin can call this function
     * @param currency The currency code to remove
     */
    function removePriceFeed(string memory currency) external onlyAdmin {
        delete priceFeeds[currency];
        delete isEthPerLocal[currency];
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
        require(recipientAddress != address(0), "Zero recipient");
        require(amountInLocalCurrency > 0, "Zero amount");
        require(
            bytes(recipientsAddressToOrgName[recipientAddress]).length != 0,
            "Recipient not registered"
        );
        require(
            priceFeeds[currencyCode] != address(0),
            "Currency not supported"
        );

        address priceFeedAddress = priceFeeds[currencyCode];
        bool ethPerLocal = isEthPerLocal[currencyCode];
        (int256 price, uint8 priceDecimals) = PriceUtils.getPriceData(
            priceFeedAddress
        );
        uint256 ethAmount = PriceUtils.convertToEth(
            amountInLocalCurrency,
            price,
            priceDecimals,
            ethPerLocal
        );

        address usdPriceFeedAddress = priceFeeds["USD"];
        require(isEthPerLocal["USD"] == false, "USD feed must be USD/ETH");
        (int256 ethUsdPrice, uint8 usdDecimals) = PriceUtils.getPriceData(
            usdPriceFeedAddress
        );
        uint256 donationInUsd = PriceUtils.convertToUsd(
            ethAmount,
            ethUsdPrice,
            usdDecimals
        );

        require(
            donationInUsd >= MINIMUM_USD,
            "Donation must be at least 1 USD"
        );
        require(msg.value >= ethAmount, "Insufficient ETH sent");
        (bool sent, ) = recipientAddress.call{value: ethAmount}("");
        require(sent, "ETH transfer failed");

        uint256 refundAmount = msg.value - ethAmount;
        if (refundAmount > 0) {
            (bool ok, ) = msg.sender.call{value: refundAmount}("");
            if (!ok) {
                refund[msg.sender] += refundAmount;
            }
        }

        emit DonationMade(
            msg.sender,
            recipientAddress,
            currencyCode,
            amountInLocalCurrency,
            ethAmount,
            donationInUsd
        );
    }

    // --- Admin Lifecycle Functions ---
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Zero admin");
        i_admin = newAdmin;
    }

    function sweep(address to) external onlyAdmin {
        require(to != address(0), "Zero addr");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "Sweep failed");
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
        (int256 price, ) = PriceUtils.getPriceData(priceFeedAddress);
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
