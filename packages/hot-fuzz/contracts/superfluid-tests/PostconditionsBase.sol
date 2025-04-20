pragma solidity ^0.8.0;

import "./Properties.sol";

contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(bytes memory returnData) internal {
        // invariant_GLOB_01();
        // invariant_GLOB_02();
        // invariant_GLOB_03();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {
        invariant_ERR(returnData);
    }
}
