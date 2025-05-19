//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsCFA is PostconditionsBase {
    function createFlowPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            _after(new address[](0), address(0));
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function deleteFlowPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
                        _after(new address[](0), address(0));

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function cfaLiquidateFlowPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function setFlowPermissionsPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function setMaxFlowPermissionsPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function revokeFlowPermissionsPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function increaseFlowRateAllowancePostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function decreaseFlowRateAllowancePostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function increaseFlowRateAllowanceWithPermissionsPostconditions(
        bool success,
        bytes memory returnData
    ) internal {
        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function decreaseFlowRateAllowanceWithPermissionsPostconditions(
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