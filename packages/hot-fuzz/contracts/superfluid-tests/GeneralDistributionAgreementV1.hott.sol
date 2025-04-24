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
import "forge-std/console.sol";
abstract contract GDAHotFuzzMixin is PostconditionsGDA {
    using SuperTokenV1Library for SuperToken;

    ISuperfluidPool[] public pools;
    bytes4 private constant SEL_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,address,uint256)"));

    function getRandomPool(uint8 input) public returns (ISuperfluidPool pool) {
        if (pools.length == 0) {
            PoolConfig memory config;
            config.transferabilityForUnitsOwner = true;
            config.distributionFromAnyAddress = true;
            createPool(input, config);
        }

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
        require(address(pool) != address(0));
        _addPool(pool);
        createPoolPostconditions(success, returnData);
    }

    event DebugPool(string s, address a);

    function maybeConnectPool(bool doConnect, uint8 a, uint8 b) public {
        (SuperfluidTester tester) = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);
        if (address(pool) == address(0)) return;

        _before(new address[](0), address(pool));
        
        bool success;
        bytes memory returnData;
        if (doConnect) {
            (success, returnData) = address(tester).call(abi.encodeWithSelector(tester.connectPool.selector,pool));
        } else {
            (success, returnData) = address(tester).call(abi.encodeWithSelector(tester.disconnectPool.selector,pool));
        }
        maybeConnectPoolPostconditions(success, returnData);
    }

    function distribute(uint8 a, uint8 b, uint128 requestedAmount) public {
        SuperfluidTester tester = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);

        _before(new address[](0), address(pool));
        (
           ISuperfluidPool.PoolIndexData memory beforeData
        ) = pool.poolOperatorGetIndex();

        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(
                tester.distribute.selector,
                address(tester),
                pool,
                requestedAmount
            )
        );
        
        distributePostconditions(success, returnData, address(pool));
    }

    function distributeFlow(uint8 a, uint8 b, uint8 c, int96 flowRate) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(c);
        flowRate = int96(fl.clamp(flowRate, -1e18, 1e18));
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(testerA).call(abi.encodeWithSelector(testerA.distributeFlow.selector,address(testerB),pool,flowRate));
        
        distributeFlowPostconditions(success, returnData,  address(testerB), address(pool), flowRate);
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
            _before(new address[](0), address(pool));
            (bool success, bytes memory returnData) = address(liquidator).call(
                abi.encodeWithSelector(liquidator.gdaLiquidate.selector, address(distributor), pool)
            );
            if (!success) liquidationFails = true;
            gdaLiquidateFlowPostconditions(success, returnData, address(distributor), address(pool));
        }
    }
  
    function updateMemberUnits(uint8 a, uint8 b, uint128 units) public {
        SuperfluidTester tester = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);
        units = uint128(fl.clamp(units, 0, uint64(type(int64).max)));
        _before(new address[](0), address(pool));

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
        amount = fl.clamp(amount, 0, pool.balanceOf(address(tester)));

        tester.approve(pool, address(testerA), amount);
        require(address(tester) != address(testerB), "self-transfer not allowed");
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                SEL_TRANSFER_FROM,
                pool,
                address(tester),
                address(testerB),
                amount
            )
        );
        poolTransferFromPostconditions(success, returnData, address(tester), address(testerB), address(pool), amount);
    }

    function poolIncreaseAllowance(
        uint8 a,
        uint8 b,
        uint256 addedValue
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);
        addedValue = fl.clamp(addedValue, 0, type(uint256).max - pool.allowance(address(testerA), address(testerB)));
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                bytes4(keccak256("increaseAllowance(address,address,uint256)")),
                pool,
                address(testerB),
                addedValue
            )
        );
        poolIncreaseAllowancePostconditions(success, returnData);
    }

    function poolDecreaseAllowance(
        uint8 a,
        uint8 b,
        uint256 subtractedValue
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);
        subtractedValue = fl.clamp(subtractedValue, 0, pool.allowance(address(testerA), address(testerB)));
        _before(new address[](0), address(pool));


        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                bytes4(keccak256("decreaseAllowance(address,address,uint256)")),
                pool,
                address(testerB),
                subtractedValue
            )
        );
        poolDecreaseAllowancePostconditions(success, returnData);
    }

    function poolApprove(
        uint8 a,
        uint8 b,
        uint256 amount
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                bytes4(keccak256("approve(address,address,uint256)")),
                pool,
                address(testerB),
                amount
            )
        );
        poolApprovePostconditions(success, returnData);
    }

    function claimAll(uint8 a, uint8 b) public {
        (SuperfluidTester tester) = _getOneTester(a);
        ISuperfluidPool pool = getRandomPool(b);
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(bytes4(keccak256("claimAll(address)")), pool)
        );
        claimAllPostconditions(success, returnData, address(tester), address(pool));
    }

    function claimAllForMember(uint8 a, uint8 b) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        ISuperfluidPool pool = getRandomPool(b);
        _before(new address[](0), address(pool));

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                bytes4(keccak256("claimAll(address,address)")),
                pool,
                address(testerB)
            )
        );
        claimAllForMemberPostconditions(success, returnData, address(testerB), address(pool));
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

contract GDAHotFuzz is GDAHotFuzzMixin {
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
