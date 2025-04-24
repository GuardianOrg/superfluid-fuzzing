// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Properties_ERR.sol";
import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";
import "forge-std/console.sol";
contract Properties_GDA is Properties_ERR {
    // Distribute
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

    // Distribute Flow Rate
    function invariant_DISTRF_01(address actor, address pool, int96 requestedRate) internal {
        if (requestedRate >= 0) {
            fl.gte(
                requestedRate,
                states[1].userStates[actor].gdaFlowRate,
                "DISTRF-01: Actual flow rate should never exceed request flow rate 01"
            );
        } else {
            fl.eq(
                states[1].userStates[actor].gdaFlowRate, 
                0, 
                "DISTRF-01: Actual flow rate should never exceed request flow rate 02"
            );
        }
    }

    // Liquidate
    function invariant_LIQ_01(address actor, address pool) internal {
        fl.eq(
            states[1].userStates[actor].gdaFlowRate,
            0,
            "LIQ-01: Post-liquidition GDA Flow Rate must be 0"
        );
    }

    function invariant_LIQ_02(address actor, address pool) internal {
        fl.eq(
            states[1].userStates[actor].gdaFlowRate,
            0,
            "LIQ-02: Post-liquidition GDA Flow Rate must be 0"
        );
    }

    // Pool Transfer Functions
    function invariant_PTRNSFR_01(address actorFrom, address actorTo, address pool, uint256 amount) internal {
        fl.eq(
            states[1].userStates[actorFrom].poolBalance, 
            states[0].userStates[actorFrom].poolBalance - amount, 
            "PTRNSFR-01: from balance not properly decreased on transferFrom"
        );
        fl.eq(
            states[1].userStates[actorTo].poolBalance, 
            states[0].userStates[actorTo].poolBalance + amount, 
            "PTRNSFR-01: to balance not properly increased on transferFrom"
        );
    }

    // Claim All
    function invariant_CLAIMALL_01(address actor, address pool) internal {
        fl.lte(
            states[1].userStates[actor].claimableBalance, 
            states[0].userStates[actor].claimableBalance, 
            "CLAIMALL-01: claimable balance should never increase after claimAll"
        );
    }
    function invariant_CLAIMALL_02(address actor, address pool) internal {
        fl.eq(
            states[1].userStates[actor].claimableBalance, 
            0, 
            "CLAIMALL-02: claimable balance should be 0 after claimAll"
        );
    }
}
