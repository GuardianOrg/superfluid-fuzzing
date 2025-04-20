// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Properties_ERR.sol";
import {
    SuperTokenV1Library
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { SuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";

contract Properties_GLOBAL is Properties_ERR {
    using SuperTokenV1Library for SuperToken;
    function invariant_GLOB_01() internal {
        fl.eq(superToken.totalSupply(), expectedTotalSupply, "GLOB-01: Total supply should equal expected supply");
    }

    function invariant_GLOB_02() internal {
        int256 liquiditySum = 0;
        address[] memory accounts = _listAccounts();
        for (uint i = 0; i < accounts.length; ++i) {
            (int256 avb, uint256 d, uint256 od, ) = superToken.realtimeBalanceOfNow(accounts[i]);
            // FIXME: correct formula
            // liquiditySum += avb + int256(d) - int256(od);
            // current faulty one
            liquiditySum += avb + (d > od ? int256(d) - int256(od) : int256(0));
        }
        fl.eq(int256(expectedTotalSupply), liquiditySum, "GLOB-02: Expected Total Supply Must Equal Liquidity Sum");
    }

    function invariant_GLOB_03() internal {
        int96 netFlowRateSum = 0;
        address[] memory accounts = _listAccounts();
        for (uint i = 0; i < accounts.length; ++i) {
            netFlowRateSum += superToken.getNetFlowRate(accounts[i]);
        }
        fl.eq(netFlowRateSum, 0, "GLOB-03: Net flow rate must be 0");
    }

}
