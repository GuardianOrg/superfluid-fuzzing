// SPDX-License-Identifier: AGPLv3
// solhint-disable reason-string
pragma solidity >= 0.8.0;

import {SuperToken} from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import "../HotFuzzBase.sol";
import "./PostconditionsCFA.sol";

abstract contract CFAHotFuzzMixin is PostconditionsCFA {
    using SuperTokenV1Library for SuperToken;

    function createFlow(uint8 a, uint8 b, int64 flowRate) public {
        require(flowRate > 0);
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        require(address(testerA) != address(testerB), "sender should not be receiver");
        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.flow.selector,
                address(testerB),
                int96(flowRate)
            )
        );
        createFlowPostconditions(success, returnData);
    }

    function deleteFlow(uint8 a, uint8 b) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);
        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.flow.selector,
                address(testerB),
                int96(0)
            )
        );
        deleteFlowPostconditions(success, returnData);
    }

    /// @notice testerA liquidates a flow from testerB to testerC
    /// @dev testerA can be the same as testerB or testerC
    function cfaLiquidateFlow(uint8 a, uint8 b, uint8 c) public {
        (SuperfluidTester liquidator, SuperfluidTester sender, SuperfluidTester recipient) = _getThreeTesters(a, b, c);

        // we first check the condition for whether a flow exists
        bool flowExists = superToken.getFlowRate(address(sender), address(recipient)) > 0;

        // then we ensure that the sender has a critical balance
        (int256 availableBalance,,,) = superToken.realtimeBalanceOfNow(address(sender));
        bool isSenderCritical = availableBalance < 0;

        // if both conditions are met, a liquidation should occur without fail
        bool isLiquidationValid = flowExists && isSenderCritical;
        if (isLiquidationValid) {
            (bool success, bytes memory returnData) = address(liquidator).call(
                abi.encodeWithSelector(
                    liquidator.cfaLiquidate.selector,
                    address(sender),
                    address(recipient)
                )
            );
        
            if (!success) liquidationFails = true;
            cfaLiquidateFlowPostconditions(success, returnData);
        }
    }

    function setFlowPermissions(
        uint8 a,
        uint8 b,
        bool allowCreate,
        bool allowUpdate,
        bool allowDelete,
        int96 flowRateAllowance
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.setFlowPermissions.selector,
                address(testerB),
                allowCreate,
                allowUpdate,
                allowDelete,
                flowRateAllowance
            )
        );
        setFlowPermissionsPostconditions(success, returnData);
    }

    function setMaxFlowPermissions(uint8 a, uint8 b) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.setMaxFlowPermissions.selector,
                address(testerB)
            )
        );
        setMaxFlowPermissionsPostconditions(success, returnData);
    }

    function revokeFlowPermissions(uint8 a, uint8 b) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.revokeFlowPermissions.selector,
                address(testerB)
            )
        );
        revokeFlowPermissionsPostconditions(success, returnData);
    }

    function increaseFlowRateAllowance(
        uint8 a,
        uint8 b,
        int96 addedFlowRateAllowance
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.increaseFlowRateAllowance.selector,
                address(testerB),
                addedFlowRateAllowance
            )
        );
        increaseFlowRateAllowancePostconditions(success, returnData);
    }

    function decreaseFlowRateAllowance(
        uint8 a,
        uint8 b,
        int96 subtractedFlowRateAllowance
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.decreaseFlowRateAllowance.selector,
                address(testerB),
                subtractedFlowRateAllowance
            )
        );
        decreaseFlowRateAllowancePostconditions(success, returnData);
    }

     function increaseFlowRateAllowanceWithPermissions(
        uint8 a,
        uint8 b,
        uint8 permissionsToAdd,
        int96 addedFlowRateAllowance
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.increaseFlowRateAllowanceWithPermissions.selector,
                address(testerB),
                permissionsToAdd,
                addedFlowRateAllowance
            )
        );
        increaseFlowRateAllowanceWithPermissionsPostconditions(success, returnData);
    }

    function decreaseFlowRateAllowanceWithPermissions(
        uint8 a,
        uint8 b,
        uint8 permissionsToRemove,
        int96 subtractedFlowRateAllowance
    ) public {
        (SuperfluidTester testerA, SuperfluidTester testerB) = _getTwoTesters(a, b);

        (bool success, bytes memory returnData) = address(testerA).call(
            abi.encodeWithSelector(
                testerA.decreaseFlowRateAllowanceWithPermissions.selector,
                address(testerB),
                permissionsToRemove,
                subtractedFlowRateAllowance
            )
        );
        decreaseFlowRateAllowanceWithPermissionsPostconditions(success, returnData);
    }
}

contract CFAHotFuzz is CFAHotFuzzMixin {
    constructor() {
        _initTesters();
    }
}
