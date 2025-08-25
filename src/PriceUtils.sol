// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title PriceUtils
/// @notice Library for price feed data fetching and currency conversion helpers

library PriceUtils {
    /// @dev Fetches latest price and decimals from a Chainlink price feed
    function getPriceData(
        address priceFeedAddress
    ) internal view returns (int256 price, uint8 decimals) {
        require(priceFeedAddress != address(0), "Price feed not available");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (uint80 rid, int256 p, , uint256 updatedAt, uint80 ans) = priceFeed
            .latestRoundData();
        require(p > 0 && ans >= rid, "Invalid price feed data");
        require(block.timestamp - updatedAt < 1 hours, "Stale price");
        price = p;
        decimals = priceFeed.decimals();
    }

    /// @dev Converts a local currency amount to ETH using price feed data
    function convertToEth(
        uint256 amountInLocalCurrency,
        int256 price,
        uint8 priceDecimals,
        bool ethPerLocal
    ) internal pure returns (uint256 ethAmount) {
        if (ethPerLocal) {
            ethAmount =
                (amountInLocalCurrency * 1e18 * uint256(price)) /
                (10 ** priceDecimals);
        } else {
            ethAmount =
                (amountInLocalCurrency * (10 ** (18 + priceDecimals))) /
                uint256(price);
        }
    }

    /// @dev Converts ETH amount to USD using the USD price feed
    function convertToUsd(
        uint256 ethAmount,
        int256 ethUsdPrice,
        uint8 usdDecimals
    ) internal pure returns (uint256 donationInUsd) {
        donationInUsd =
            (ethAmount * uint256(ethUsdPrice)) /
            (10 ** usdDecimals);
    }
}
