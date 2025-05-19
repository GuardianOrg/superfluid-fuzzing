//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsCM is PostconditionsBase {
    bool internal constant IS_ECHIDNA = true; // Set to true when running in Echidna, false for Foundry
    
    // Use the fixed path for both environments
    string internal constant REVERTED_ACTION_PATH = "/Users/vladimirdzotov/Dropbox/do/superfluid-fuzzing/packages/hot-fuzz/contracts/logs/revertedActionInQueue.txt";

    function readRevertedActionFile() internal returns (bool) {
        string[] memory inputs = new string[](3);
        inputs[0] = "/bin/sh";
        inputs[1] = "-c";
        inputs[2] = string(abi.encodePacked("cat ", REVERTED_ACTION_PATH));
        bytes memory result = vm.ffi(inputs);
        
        // If the file contains "1", return true, otherwise return false
        return result.length > 0 && result[0] == bytes1("1");
    }

    function createCMFlowPostconditions(
        bool success,
        bytes memory returnData,
        uint256 flowType
    ) internal {
        if (flowType == 1) {
            onDeleteFlow(success, returnData);
        } else if (flowType == 2) {
            onCreateFlow(success, returnData);
        } else if (flowType == 3) {
            onUpdateFlow(success, returnData);
        }
    }

    function onCreateFlow(bool success, bytes memory returnData) internal {
        if (success) {
            _after(new address[](0), address(0));
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function onUpdateFlow(bool success, bytes memory returnData) internal {
        if (success) {
            _after(new address[](0), address(0));
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function onDeleteFlow(bool success, bytes memory returnData) internal {
        if (success) {
            _after(new address[](0), address(0));
            console.log("onDeleteFlow");
            cmRevertedThisQueue = readRevertedActionFile();
            console.log("cmRevertedThisQueue", cmRevertedThisQueue);

            if (cmRevertedThisQueue) {
                fl.t(sf.host.isAppJailed(chaosMonkey), "ChaosMonkey should be jailed after malicious revert");
            }
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}