// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFuzzer {
    function setExpectedTotalSupply(uint256 expectedTotalSupply) external;

    function getExpectedTotalSupply() external view returns (uint256);


}
