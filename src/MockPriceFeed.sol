// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockPriceFeed {
    int256 public latestAnswer;

    constructor(int256 _price) {
        latestAnswer = _price;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // Return dummy values for roundId, answer, startedAt, updatedAt, answeredInRound
        return (0, latestAnswer, 0, 0, 0);
    }
}
