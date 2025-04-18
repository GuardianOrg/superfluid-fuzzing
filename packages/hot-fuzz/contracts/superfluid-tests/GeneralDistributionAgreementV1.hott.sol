// SPDX-License-Identifier: AGPLv3
// solhint-disable reason-string
pragma solidity >= 0.8.0;

import {SuperToken} from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {HotFuzzBase, SuperfluidTester} from "../HotFuzzBase.sol";
import "./PostconditionsGDA.sol";

abstract contract GDAHotFuzzMixin is HotFuzzBase, PostconditionsGDA {
    using SuperTokenV1Library for SuperToken;

    ISuperfluidPool[] public pools;

    function getRandomPool(uint8 input) public view returns (ISuperfluidPool pool) {
        if (pools.length > 0) {
            pool = pools[input % (pools.length)];
        }
    }

   function createPool(uint8 a, PoolConfig memory config) public {
        SuperfluidTester tester = _getOneTester(a);
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(tester.createPool.selector, address(tester), config)
        );
        ISuperfluidPool pool = abi.decode(returnData, (ISuperfluidPool));
        _addPool(pool);
        createPoolPostconditions(success, returnData);
    }

    event DebugPool(string s, address a);

    function maybeConnectPool(bool doConnect, uint8 a, uint8 b) public {
        (SuperfluidTester tester) = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);
        if (address(pool) == address(0)) return;
        bool success;
        bytes memory returnData;
        if (doConnect) {
            (success, returnData) = address(tester).call(abi.encodeWithSelector(tester.connectPool.selector,pool));
        } else {
            (success, returnData) = address(tester).call(abi.encodeWithSelector(tester.disconnectPool.selector,pool));
        }
    }

    function distribute(uint8 a, uint8 b, uint128 requestedAmount) public {
        SuperfluidTester tester = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);

        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(
                tester.distribute.selector,
                address(tester),
                pool,
                requestedAmount
            )
        );
        // distributePostconditions(success, returnData);
    }

    function distributeFlow(uint8 a, uint8 b, uint8 c, int96 flowRate) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(c);
        flowRate = int96(fl.clamp(flowRate, 1, 1e18));
        (bool success, bytes memory returnData) = address(testerA).call(abi.encodeWithSelector(testerA.distributeFlow.selector,address(testerB),pool,flowRate));
        distributeFlowPostconditions(success, returnData);
    }

    /// @notice testerA liquidates a flow from testerB to pool
    /// @dev testerA can be the same as testerB
    function gdaLiquidateFlow(uint8 a, uint8 b, uint8 c) public {
        (SuperfluidTester liquidator, SuperfluidTester distributor) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(c);

        // check existing flow & balance conditions
        bool flowExists = superToken.getFlowDistributionFlowRate(address(distributor), pool) > 0;
        (int256 availableBalance,,,) = superToken.realtimeBalanceOfNow(address(distributor));
        bool isDistributorCritical = availableBalance < 0;

        if (flowExists) {
            fl.log("Flow exists");
        }
        if (isDistributorCritical) {
            fl.log("Distributor critical");
        }
        int96 flowRate = superToken.getFlowDistributionFlowRate(address(distributor), pool);
        if (flowRate == 0) {
            fl.log("==0");
        }
        else if (flowRate > 0) {
            fl.log(">0");
        }
        else if (flowRate < -1e18) {
            fl.log("< -1e18");
        }
        else {
            fl.log("Between 0 and -1e18");
        }

        // if both conditions are met, a liquidation should occur without fail
        bool isLiquidationValid = flowExists && isDistributorCritical;
        if (isLiquidationValid) {
            (bool success, bytes memory returnData) = address(liquidator).call(
                abi.encodeWithSelector(liquidator.gdaLiquidate.selector, address(distributor), pool)
            );
            if (!success) liquidationFails = true;
            gdaLiquidateFlowPostconditions(success, returnData);
        }
    }
  
    function updateMemberUnits(uint8 a, uint8 b, uint128 units) public {
        SuperfluidTester tester = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(
                tester.updateMemberUnits.selector,
                pool,
                address(tester),
                units
            )
        );
        updateMemberUnitsPostconditions(success, returnData);
    }

    function poolTransferFrom(uint8 a, uint8 b, uint8 c, uint256 amount) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        (SuperfluidTester tester) = _getOneTester(c);
        ISuperfluidPool pool = getRandomPool(b);

        testerA.transferFrom(pool, address(tester), address(testerB), amount);
    }

    function poolIncreaseAllowance(uint8 a, uint8 b, uint256 addedValue) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);

        testerA.increaseAllowance(pool, address(testerB), addedValue);
    }

    function poolDecreaseAllowance(uint8 a, uint8 b, uint256 subtractedValue) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);

        testerA.decreaseAllowance(pool, address(testerB), subtractedValue);
    }

    function poolApprove(uint8 a, uint8 b, uint256 amount) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);

        testerA.approve(pool, address(testerB), amount);
    }

    function claimAll(uint8 a, uint8 b) public {
        (SuperfluidTester tester) = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);

        tester.claimAll(pool);
    }

    function claimAllForMember(uint8 a, uint8 b) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);

        testerA.claimAll(pool, address(testerB));
    }

    function _addPool(ISuperfluidPool pool) internal {
        // if (address(pool) != address(0)) {
        //     fl.log("Pool address:", address(pool));
        //     fl.t(false, "<_addPool> NON 0 ADDRESS");
        // }
        pools.push(pool);

        _addAccount(address(pool));
    }
}

contract GDAHotFuzz is HotFuzzBase(10), GDAHotFuzzMixin {
    uint256 public constant NUM_POOLS = 3;

    constructor() {
        _initTesters();

        PoolConfig memory config = PoolConfig({transferabilityForUnitsOwner: true, distributionFromAnyAddress: true});

        for (uint256 i; i < NUM_POOLS; i++) {
            (SuperfluidTester tester) = _getOneTester(uint8(i));
            ISuperfluidPool pool = tester.createPool(address(tester), config);
            _addPool(pool);
        }
    }
}
