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
}
