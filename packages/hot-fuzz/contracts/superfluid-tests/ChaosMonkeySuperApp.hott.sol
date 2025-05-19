// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ChaosMonkeySuperApp} from "./SuperApps/ChaosMonkeySuperApp.sol";
import {ISuperfluidPool} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./ConstantFlowAgreementV1.hott.sol";
import "./GeneralDistributionAgreementV1.hott.sol";
import "./SuperToken.hott.sol";
import "./PostconditionsCM.sol";

contract SuperAppHotFuzzMixin is
    CFAHotFuzzMixin,
    GDAHotFuzzMixin,
    SuperTokenHotFuzzMixin,
    PostconditionsCM
{
    int256 private constant MAX_INT96 = int256(type(int96).max);
    uint256 private constant MAX_UINT128 = uint256(type(uint128).max);
    uint256 private constant MAX_GAS_BURN = 1_000_000;

    // Clear the action queue
    function clearChaosMonkeyQueue() public {
        chaosMonkey.clearActionQueue();
    }

    // Add a random action to the queue
    function addChaosMonkeyAction(
        uint8 actionTypeSeed,
        uint8 a,
        uint8 b,
        uint128 amount,
        int96 flowRate
    ) public {
        ChaosMonkeySuperApp.ActionType actType = ChaosMonkeySuperApp.ActionType(
            actionTypeSeed % 32
        );
        bytes memory data;

        if (
            actType == ChaosMonkeySuperApp.ActionType.CreateFlow ||
            actType == ChaosMonkeySuperApp.ActionType.UpdateFlow
        ) {
            address receiver = address(_getOneTester(b));
            flowRate = int96((fl.clamp(int256(flowRate), 0, MAX_INT96)));
            data = abi.encode(receiver, flowRate);
            fl.log("addChaosMonkeyAction:CreateFlow/UpdateFlow");
        } else if (actType == ChaosMonkeySuperApp.ActionType.CfaLiquidate) {
            address sender = address(_getOneTester(a));
            address receiver = address(_getOneTester(b));
            data = abi.encode(sender, receiver);
            fl.log("addChaosMonkeyAction:DeleteFlow/CfaLiquidate");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.Distribute ||
            actType == ChaosMonkeySuperApp.ActionType.ClaimAll
        ) {
            ISuperfluidPool pool = getRandomPool(a);
            amount = uint128(fl.clamp(amount, 0, MAX_UINT128));
            if (actType == ChaosMonkeySuperApp.ActionType.Distribute) {
                data = abi.encode(address(pool), amount);
                fl.log("addChaosMonkeyAction:Distribute");
            } else {
                data = abi.encode(address(pool));
                fl.log("addChaosMonkeyAction:ClaimAll");
            }
        } else if (actType == ChaosMonkeySuperApp.ActionType.DistributeFlow) {
            ISuperfluidPool pool = getRandomPool(a);
            flowRate = int96((fl.clamp(flowRate, 0, MAX_INT96)));
            data = abi.encode(address(pool), flowRate);
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.Transfer ||
            actType == ChaosMonkeySuperApp.ActionType.Approve
        ) {
            address receiver = address(_getOneTester(b));
            amount = uint128(fl.clamp(amount, 0, MAX_UINT128));
            data = abi.encode(receiver, amount);
            fl.log("addChaosMonkeyAction:Transfer/Approve");
        } else if (actType == ChaosMonkeySuperApp.ActionType.TransferFrom) {
            address sender = address(_getOneTester(a));
            address receiver = address(_getOneTester(b));
            amount = uint128(fl.clamp(amount, 0, MAX_UINT128));
            data = abi.encode(sender, receiver, amount);
            fl.log("addChaosMonkeyAction:TransferFrom");
        } else if (actType == ChaosMonkeySuperApp.ActionType.TransferAll) {
            address receiver = address(_getOneTester(b));
            data = abi.encode(receiver);
            fl.log("addChaosMonkeyAction:TransferAll");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.IncreaseAllowance ||
            actType == ChaosMonkeySuperApp.ActionType.DecreaseAllowance
        ) {
            address spender = address(_getOneTester(b));
            amount = uint128(fl.clamp(amount, 0, MAX_UINT128));
            data = abi.encode(spender, amount);
            fl.log("addChaosMonkeyAction:Inc/DecAllowance");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.ConnectPool ||
            actType == ChaosMonkeySuperApp.ActionType.DisconnectPool
        ) {
            ISuperfluidPool pool = getRandomPool(a);
            data = abi.encode(address(pool));
            fl.log("addChaosMonkeyAction:Connect/DisconnectPool");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.SetMaxFlowPermissions
        ) {
            address flowOperator = address(_getOneTester(b));
            data = abi.encode(flowOperator);
            fl.log("addChaosMonkeyAction:SetMaxFlowPermissions");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.RevokeFlowPermissions
        ) {
            address flowOperator = address(_getOneTester(b));
            data = abi.encode(flowOperator);
            fl.log("addChaosMonkeyAction:RevokeFlowPermissions");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.SetFlowPermissions
        ) {
            address flowOperator = address(_getOneTester(b));
            bool allowCreate = (a % 2 == 0);
            bool allowUpdate = (b % 2 == 0);
            bool allowDelete = ((a + b) % 2 == 0);
            int96 allowance = int96(fl.clamp(int256(flowRate), 0, MAX_INT96));
            data = abi.encode(
                flowOperator,
                allowCreate,
                allowUpdate,
                allowDelete,
                allowance
            );
            fl.log("addChaosMonkeyAction:SetFlowPermissions");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.Upgrade ||
            actType == ChaosMonkeySuperApp.ActionType.Downgrade
        ) {
            amount = uint128(fl.clamp(amount, 0, MAX_UINT128));
            data = abi.encode(amount);
            fl.log("addChaosMonkeyAction:Upgrade/Downgrade");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.UpdateMemberUnits
        ) {
            ISuperfluidPool pool = getRandomPool(a);
            address member = address(_getOneTester(b));
            uint128 units = uint128(fl.clamp(amount, 0, MAX_UINT128));
            data = abi.encode(address(pool), member, units);
            fl.log("addChaosMonkeyAction:UpdateMemberUnits");
        } else if (actType == ChaosMonkeySuperApp.ActionType.Revert) {
            data = abi.encode("ChaosMonkey Revert");
            fl.log("addChaosMonkeyAction:Revert");
        } else if (actType == ChaosMonkeySuperApp.ActionType.BurnGas) {
            uint256 gasToBurn = fl.clamp(amount, 0, MAX_GAS_BURN);
            data = abi.encode(gasToBurn);
            fl.log("addChaosMonkeyAction:BurnGas");
        } else if (
            actType == ChaosMonkeySuperApp.ActionType.ReturnEmptyCtx ||
            actType == ChaosMonkeySuperApp.ActionType.ReturnInvalidCtx
        ) {
            data = new bytes(0);
            fl.log("addChaosMonkeyAction:Return*_Ctx");
        } else if (actType == ChaosMonkeySuperApp.ActionType.CallAnotherApp) {
            data = new bytes(42);
            fl.log("addChaosMonkeyAction:CallAnotherApp");
        } else {
            data = new bytes(0); // Noop
            fl.log("addChaosMonkeyAction:Noop");
        }

        chaosMonkey.addAction(actType, data);
    }

    // Trigger a flow to the Chaos Monkey to invoke callbacks
    function createFlowToChaosMonkey(uint8 a, int96 flowRate) public {
        SuperfluidTester tester = _getOneTester(a);

        flowRate = int96(fl.clamp(int256(flowRate), 0, MAX_INT96));
        uint256 flowType = checkFlowRate(a, flowRate);
        console.log("flowType", flowType);
        chaosMonkey.setCalledFlow(flowType);

        _before(new address[](0), address(0)); //every pool is checked

        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodeWithSelector(
                tester.flow.selector,
                address(chaosMonkey),
                flowRate
            )
        );
        createCMFlowPostconditions(success, returnData, flowType);

        chaosMonkey.writeSucceededActionBool();

        console.log("createFlowToChaosMonkey done");
    }

    function checkFlowRate(uint8 a, int96 flowRate) internal returns (uint256) {
        SuperfluidTester tester = _getOneTester(a);
        (, int96 currentFlowRate, , ) = sf.cfa.getFlow(
            superToken,
            address(tester),
            address(chaosMonkey)
        );

        if (flowRate == 0) {
            return 1; // delete
        } else if (currentFlowRate == 0) {
            return 2; // create
        } else {
            return 3; // update
        }
    }

    function setChaosMonkeyRevertedThisQueue(bool value) public {
        cmRevertedThisQueue = value;
    }

    function getChaosMonkeyRevertedThisQueue() public view returns (bool) {
        return cmRevertedThisQueue;
    }

    // -----------------------------------------------------------------------------
    // Helpers to put multiple Chaos Monkey actions in one call
    // -----------------------------------------------------------------------------

    function addChaosMonkeyActions(
        uint8[] memory actionTypeSeeds,
        uint8[] memory a,
        uint8[] memory b,
        uint128[] memory amount,
        int96[] memory flowRate
    ) public {
        uint256 len = actionTypeSeeds.length;
        require(
            len >= 2 && len <= 10,
            "ChaosMonkey: actions count must be 2-10"
        );
        require(
            a.length == len &&
                b.length == len &&
                amount.length == len &&
                flowRate.length == len,
            "ChaosMonkey: parameter length mismatch"
        );
        for (uint256 i = 0; i < len; ++i) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    /**
     * Wrappers
     */
    function addChaosMonkeyActions2(
        uint8[2] memory actionTypeSeeds,
        uint8[2] memory a,
        uint8[2] memory b,
        uint128[2] memory amount,
        int96[2] memory flowRate
    ) public {
        for (uint8 i = 0; i < 2; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions3(
        uint8[3] memory actionTypeSeeds,
        uint8[3] memory a,
        uint8[3] memory b,
        uint128[3] memory amount,
        int96[3] memory flowRate
    ) public {
        for (uint8 i = 0; i < 3; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions4(
        uint8[4] memory actionTypeSeeds,
        uint8[4] memory a,
        uint8[4] memory b,
        uint128[4] memory amount,
        int96[4] memory flowRate
    ) public {
        for (uint8 i = 0; i < 4; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions5(
        uint8[5] memory actionTypeSeeds,
        uint8[5] memory a,
        uint8[5] memory b,
        uint128[5] memory amount,
        int96[5] memory flowRate
    ) public {
        for (uint8 i = 0; i < 5; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions6(
        uint8[6] memory actionTypeSeeds,
        uint8[6] memory a,
        uint8[6] memory b,
        uint128[6] memory amount,
        int96[6] memory flowRate
    ) public {
        for (uint8 i = 0; i < 6; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions7(
        uint8[7] memory actionTypeSeeds,
        uint8[7] memory a,
        uint8[7] memory b,
        uint128[7] memory amount,
        int96[7] memory flowRate
    ) public {
        for (uint8 i = 0; i < 7; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions8(
        uint8[8] memory actionTypeSeeds,
        uint8[8] memory a,
        uint8[8] memory b,
        uint128[8] memory amount,
        int96[8] memory flowRate
    ) public {
        for (uint8 i = 0; i < 8; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions9(
        uint8[9] memory actionTypeSeeds,
        uint8[9] memory a,
        uint8[9] memory b,
        uint128[9] memory amount,
        int96[9] memory flowRate
    ) public {
        for (uint8 i = 0; i < 9; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    function addChaosMonkeyActions10(
        uint8[10] memory actionTypeSeeds,
        uint8[10] memory a,
        uint8[10] memory b,
        uint128[10] memory amount,
        int96[10] memory flowRate
    ) public {
        for (uint8 i = 0; i < 10; i++) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }

    // Internal generic function to loop over fixed-size arrays
    function _addChaosMonkeyActionsFixed(
        uint8[] memory actionTypeSeeds,
        uint8[] memory a,
        uint8[] memory b,
        uint128[] memory amount,
        int96[] memory flowRate
    ) private {
        uint256 len = actionTypeSeeds.length;
        for (uint256 i = 0; i < len; ++i) {
            addChaosMonkeyAction(
                actionTypeSeeds[i],
                a[i],
                b[i],
                amount[i],
                flowRate[i]
            );
        }
    }
}
