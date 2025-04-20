//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsGDA is PostconditionsBase {
    function createPoolPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function maybeConnectPoolPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function distributePostconditions(
        bool success,
        bytes memory returnData,
        address pool
    ) internal {
        _after(new address[](0), pool);
        if (success) {
            invariant_DISTR_01(pool);
            invariant_DISTR_02(pool);
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function distributeFlowPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function gdaLiquidateFlowPostconditions(
        bool success,
        bytes memory returnData,
        address actor,
        address pool
    ) internal {
        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = actor;
        _after(actorsToUpdate, pool);
        
        if (success) {
            invariant_LIQ_01(actor, pool);
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function updateMemberUnitsPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function poolTransferPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function poolTransferFromPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function poolIncreaseAllowancePostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function poolDecreaseAllowancePostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function poolApprovePostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function claimAllPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function claimAllForMemberPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}