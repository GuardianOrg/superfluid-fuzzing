// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Properties_ERR.sol";
import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";

contract Properties_GLOBAL is Properties_ERR {
    function invariant_GLOB_01() internal {
        fl.eq(superToken.totalSupply(), expectedTotalSupply, "GLOB-01: Total supply should equal expected supply");
    }
    // function echidna_check_total_supply() public view returns (bool) {
    //     assert(superToken.totalSupply() == expectedTotalSupply);
    //     return superToken.totalSupply() == expectedTotalSupply;
    // }

    // function echidna_check_liquiditySumInvariance() public view returns (bool) {
    //     int256 liquiditySum = 0;
    //     address[] memory accounts = _listAccounts();
    //     for (uint i = 0; i < accounts.length; ++i) {
    //         (int256 avb, uint256 d, uint256 od, ) = superToken.realtimeBalanceOfNow(accounts[i]);
    //         // FIXME: correct formula
    //         // liquiditySum += avb + int256(d) - int256(od);
    //         // current faulty one
    //         liquiditySum += avb + (d > od ? int256(d) - int256(od) : int256(0));
    //     }
    //     assert(int256(expectedTotalSupply) == liquiditySum);
    //     return int256(expectedTotalSupply) == liquiditySum;
    // }

    // function echidna_check_netFlowRateSumInvariant() public view returns (bool) {
    //     int96 netFlowRateSum = 0;
    //     address[] memory accounts = _listAccounts();
    //     for (uint i = 0; i < accounts.length; ++i) {
    //         netFlowRateSum += superToken.getNetFlowRate(accounts[i]);
    //     }
    //     assert(netFlowRateSum == 0);
    //     return netFlowRateSum == 0;
    // }

}
