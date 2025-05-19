pragma solidity ^0.8.0;

import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";
import {HotFuzzBase} from "../../HotFuzzBase.sol";
import {IGeneralDistributionAgreementV1} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import "forge-std/console.sol";
contract BeforeAfter is HotFuzzBase {
    
    mapping(uint8 => State) states;
   
    struct PoolState {
        uint256 totalUnits;
        ISuperfluidPool.PoolIndexData poolIndexData;
    }

    struct UserState {
        uint256 tokenBalance;
        int96 gdaFlowRate;
        uint256 poolBalance;
        int256 claimableBalance;
    }

    struct State {
        mapping(address => UserState) userStates;
        mapping(address => PoolState) poolStates;
    }

    struct ActorStates {
        uint256 vaultTokenBalance;
    }

    function _before(address[] memory actors, address pool) internal {
        _setStates(0, actors, pool);
    }

    function _after(address[] memory actors, address pool) internal {
        _setStates(1, actors, pool);
    }

    function _setStates(uint8 callNum, address[] memory actors, address pool) internal {
        _processActors(callNum, actors, pool);
        _updateCommonState(callNum, pool);
    }

    function _processActors(uint8 callNum, address[] memory actors, address pool) private {
        // for (uint256 i = 0; i < actors.length; i++) {
        //     _setActorState(callNum, actors[i]);
        // }
        // @audit Loop through all testers for now to simplify suite build.
        for (uint256 i = 0; i < testers.length; i++) {
            console.log("Setting actor state for", i);
            for (uint256 j = 0; j < pools.length; j++) {
                if (address(pools[j]) == address(0)) continue;
                _setActorState(callNum, address(testers[i]), address(pools[j]));
            }
        }
    }

    function _updateCommonState(uint8 callNum, address pool) private {
       for (uint256 i = 0; i < pools.length; i++) {
       if (address(pools[i]) == address(0)) continue;
        _updatePoolState(callNum, address(pools[i]));
       }
        
    }

    function _setActorState(uint8 callNum, address actor, address pool) internal {
        states[callNum].userStates[actor].gdaFlowRate = IGeneralDistributionAgreementV1(address(sf.gda)).getFlowRate(superToken, actor, ISuperfluidPool(pool));
        states[callNum].userStates[actor].poolBalance = ISuperfluidPool(pool).balanceOf(actor);
        (states[callNum].userStates[actor].claimableBalance, ) = ISuperfluidPool(pool).getClaimableNow(actor);
    }

    function _updatePoolState(uint8 callNum, address pool) internal {
        PoolState storage poolState = states[callNum].poolStates[pool];
        poolState.totalUnits = ISuperfluidPool(pool).getTotalUnits();
        (
            poolState.poolIndexData
        ) = ISuperfluidPool(pool).poolOperatorGetIndex();
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}