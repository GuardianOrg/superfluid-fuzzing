// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.23;

import { FoundrySuperfluidTester } from "../../foundry/FoundrySuperfluidTester.t.sol";
import { ISuperfluidPool, SuperfluidPool } from "../../../contracts/agreements/gdav1/SuperfluidPool.sol";
import { SuperTokenV1Library } from "../../../contracts/apps/SuperTokenV1Library.sol";
import { ISuperToken, SuperToken } from "../../../contracts/superfluid/SuperToken.sol";
import "../../../../hot-fuzz/contracts/superfluid-tests/SuperHotFuzz.sol";
import { ERC1820RegistryCompiled } from "../../../contracts/libs/ERC1820RegistryCompiled.sol";
import "forge-std/Test.sol";


/// @dev This contract includes test sequences discovered by echidna which broke invariants previously.
contract EchidnaReproduce is SuperHotFuzz, Test {
    using SuperTokenV1Library for ISuperToken;

    // ROOT CAUSE: `toSemanticMoneyUnit` uint128 cannot fit into int128, hence SafeCast: value doesn't fit in 128 bits revert.
    // Fixed with clamping to uint64.max within handler function.
    function testUpdateUnitsEmptyRevert() public {
       updateMemberUnits(0,0,170397380159611669441227919161889835218);
    }

    // ROOT CAUSE: `mu.pool_member_update(p, wrappedUnits, t);` since `Unit newTotalUnit = oldTotalUnit + u - b1.m.owned_units;` exceeds int128 max value, hence panic overflow
    // Hit when handler clamp is units = uint128(fl.clamp(units, 0, uint64(type(int128).max)));
    function testUpdateUnitsPanicRevert() public {
        updateMemberUnits(1,0,30145910450658696313993340657934279484);
        updateMemberUnits(0,0,32215256899813453682377679564679195217);
        updateMemberUnits(0,0,107879475497138386906674755164220517012);
    }

    // ROOT CAUSE: Lack of allowance after balance is added and transfer is attempted.
    // Fixed with approve in transferFrom handler function
    function testTransferFromPanicRevert() public {
        updateMemberUnits(0,0,1);
        poolTransferFrom(0,0,0,1);
    }

    // ROOT CAUSE: Revert within increaseFlowRateAllowanceWithPermissions due to int96 newFlowRateAllowance = oldFlowRateAllowance + addedFlowRateAllowance; overflow revert.
    // Fixed with clamping within poolDecreaseAllowance
    function testIncreaseFlowRateAllowanceTargetPanicked() public {
        maybeConnectPool(false,0,0);
        increaseFlowRateAllowance(252,255,24076480938201138371799179485);
        increaseFlowRateAllowance(5,34,16134934835402215511660541702);
    }

    // ROOT CAUSE: Revert within increaseAllowance as addedValue is a large value and leads to overflow when adding to existing allowance
    // Fixed with clamping within poolIncreaseAllowance
    function testIncreaseAllowancePanic() public {
        poolIncreaseAllowance(0,0,0);
        poolApprove(21,8,612442562458672454002362005479039230215856049958800852273497177480331085578);
        poolIncreaseAllowance(164,8,115183460409007582237719538714803597407649724829487892977901832368525523844240);
    }
}
