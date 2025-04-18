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
        bytes memory returnData
    ) internal {
        if (success) {
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
        bytes memory returnData
    ) internal {
        if (success) {
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