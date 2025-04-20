// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Properties_ERR.sol";
import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";

contract Properties_GDA is Properties_ERR {
    function invariant_DISTR_01(address pool) internal {
        fl.eq(
            states[1].poolStates[pool].totalUnits,
            states[0].poolStates[pool].totalUnits,
            "DISTR-01: Pool units should be the same after distribute"
        );
    }

    function invariant_DISTR_02(address pool) internal {
        fl.gte(
            states[1].poolStates[pool].poolIndexData.wrappedSettledValue,
            states[0].poolStates[pool].poolIndexData.wrappedSettledValue,
            "DISTR-02: Wrapped settled value should increase after distribute"
        );
    }

    function invariant_LIQ_01(address actor, address pool) internal {
        fl.eq(
            states[1].userStates[actor].gdaFlowRate,
            0,
            "LIQ-01: Post-liquidition GDA Flow Rate must be 0"
        );
    }
}
