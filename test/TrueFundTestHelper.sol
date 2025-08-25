// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";
import {TrueFund} from "../src/TrueFund.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract TrueFundTestHelper {
    Vm internal constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function deployMockFeed(
        uint8 decimals,
        int256 price
    ) internal returns (MockV3Aggregator) {
        return new MockV3Aggregator(decimals, price);
    }

    function setupRecipientAndFeeds(
        TrueFund trueFund,
        address admin,
        address recipient,
        string memory orgName,
        string memory currency,
        address feed,
        bool ethPerLocal,
        address usdFeed,
        bool usdEthPerLocal
    ) internal {
        vm.prank(admin);
        trueFund.registerRecipientWithOrg(recipient, orgName);
        vm.prank(admin);
        trueFund.addPriceFeed(currency, feed, ethPerLocal);
        vm.prank(admin);
        trueFund.addPriceFeed("USD", usdFeed, usdEthPerLocal);
    }

    function calcEthAmount(
        uint256 amountInLocalCurrency,
        int256 price,
        uint8 priceDecimals,
        bool ethPerLocal
    ) internal pure returns (uint256) {
        if (ethPerLocal) {
            return
                (amountInLocalCurrency * 1e18 * uint256(price)) /
                (10 ** priceDecimals);
        } else {
            return
                (amountInLocalCurrency * (10 ** (18 + priceDecimals))) /
                uint256(price);
        }
    }

    function calcAmountInLocalCurrency(
        uint256 ethAmount,
        int256 price,
        uint8 priceDecimals,
        bool ethPerLocal
    ) internal pure returns (uint256) {
        if (ethPerLocal) {
            return
                (ethAmount * (10 ** uint256(priceDecimals))) / uint256(price);
        } else {
            return (ethAmount * uint256(price)) / (10 ** (18 + priceDecimals));
        }
    }
}
