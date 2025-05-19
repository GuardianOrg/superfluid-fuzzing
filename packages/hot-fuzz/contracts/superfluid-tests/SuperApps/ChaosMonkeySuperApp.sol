// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {
    ISuperfluid,
    ISuperApp,
    ISuperToken,
    ISuperfluidPool,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IConstantFlowAgreementV1, SuperfluidTester} from "../../SuperfluidTester.sol";

// import {IConstantFlowAgreementV1} from
//     "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import "forge-std/console.sol";
import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "@perimetersec/fuzzlib/src/IHevm.sol";
import {TestToken} from "@superfluid-finance/ethereum-contracts/contracts/utils/TestToken.sol";

import {IFuzzer} from "../../IFuzzer.sol";

contract ChaosMonkeySuperApp is ISuperApp, FuzzBase {
    using SuperTokenV1Library for ISuperToken;

    ISuperfluid private _host;
    IConstantFlowAgreementV1 private _cfa;
    TestToken private _token;
    ISuperToken private _superToken;
    SuperfluidTester[] private _testers; // Tester accounts for random interactions
    ISuperApp private _otherApp; // For testing forbidden calls
    IFuzzer private _fuzzer;
    
    
    enum FlowState {
        None,
        Create,
        Update,
        Delete
    }

    FlowState private _flowState;

    enum ActionType {
        Noop, // Do nothing
        CreateFlow, // Create a CFA flow
        UpdateFlow, // Update a CFA flow
        CfaLiquidate, // Liquidate a CFA flow (delete as operator)
        Distribute, // Distribute to a pool
        DistributeFlow, // Stream to a pool
        Transfer, // Transfer tokens
        Approve, // Approve tokens
        TransferFrom, // Transfer tokens from
        TransferAll, // Transfer entire balance
        IncreaseAllowance, // Increase allowance on token
        DecreaseAllowance, // Decrease allowance on token
        Upgrade, // Upgrade underlying token
        Downgrade, // Downgrade SuperToken
        SetFlowPermissions, // Update flow operator permissions
        SetMaxFlowPermissions, // Give max flow permissions
        RevokeFlowPermissions, // Revoke flow permissions
        ConnectPool, // Connect to pool
        DisconnectPool, // Disconnect from pool
        UpdateMemberUnits, // Update pool member units
        ClaimAll, // Claim from pool
        PoolIncreaseAllowance, // ERC20 increaseAllowance on pool
        PoolDecreaseAllowance, // ERC20 decreaseAllowance on pool
        PoolApprove, // ERC20 approve on pool
        Revert, // Revert with reason
        BurnGas, // Consume gas
        ReturnEmptyCtx, // Return empty context
        ReturnInvalidCtx, // Return invalid context
        ReturnValidCtx, // Return valid context
        CallAnotherApp // Attempt to call another Super App (forbidden)

    }

    struct Action {
        ActionType actionType;
        bytes data; // Encoded parameters (e.g., flow rate, amount, reason)
    }

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        TestToken token,
        ISuperToken superToken,
        SuperfluidTester[] memory testers,
        ISuperApp otherApp,
        address fuzzer
    ) {
        _host = host;
        _cfa = cfa;
        _token = token;
        _superToken = superToken;
        _testers = testers;
        _otherApp = otherApp;
        _host.registerAppWithKey(SuperAppDefinitions.APP_LEVEL_FINAL, "");
        _fuzzer = IFuzzer(fuzzer);
    }

    Action[] private _actionQueue; // Queue of actions for the next callback
    mapping(bytes32 => bool) private _flows; // Track flows for deletion testing
    uint256 private constant MAX_ACTIONS = 10; // Limit actions per callback for performance
    bytes constant VALID_CTX = bytes("");

    // *** LOGGING BLOCK START ***
    string internal constant LOG_PATH = "./contracts/logs/chaosMonkeyActions.txt";
    string internal constant REVERTED_ACTION_PATH = "./contracts/logs/revertedActionInQueue.txt";


    function setCalledFlow(uint256 index) public {
        if (index == 1) {
            _flowState = FlowState.Delete;
        } else if (index == 2) {
            _flowState = FlowState.Create;
        } else if (index == 3) {
            _flowState = FlowState.Update;
        }
        fl.log("FLOW", uint256(_flowState));
    }


    function resetFlowState() private {
        _flowState = FlowState.None;
    }

    function onActionSucceeded(ActionType actionType, bytes memory /*data*/ ) internal {
        _logAction(actionType, "succeeded");
    }

    function onActionReverted(ActionType actionType, bytes memory /*data*/ ) internal {
        _logAction(actionType, "reverted");
      
        fl.log("FLOW", uint256(_flowState));
      
    }

    function _logAction(ActionType actionType, string memory outcome) internal {
        string memory line = string(abi.encodePacked(_actionTypeToString(actionType), " | ", outcome));

        string[] memory inputs = new string[](3);
        inputs[0] = "/bin/sh";
        inputs[1] = "-c";
        inputs[2] = string(abi.encodePacked("echo \"", line, "\" >> ", LOG_PATH));
        vm.ffi(inputs);
    }

    function writeSucceededActionBool() public {
        string memory line = string(abi.encodePacked("0"));

        string[] memory inputs = new string[](3);
        inputs[0] = "/bin/sh";
        inputs[1] = "-c";
        inputs[2] = string(abi.encodePacked("echo \"", line, "\" > ", REVERTED_ACTION_PATH));
        vm.ffi(inputs);
                
    }

    function writeRevertedActionBool() internal {
         string memory line = string(abi.encodePacked("1"));

        string[] memory inputs = new string[](3);
        inputs[0] = "/bin/sh";
        inputs[1] = "-c";
        inputs[2] = string(abi.encodePacked("echo \"", line, "\" > ", REVERTED_ACTION_PATH));
        vm.ffi(inputs);
    }

    function _logStateReset() internal {
        if (_actionQueue.length == 0) {
            string[] memory inputs = new string[](3);
            inputs[0] = "/bin/sh";
            inputs[1] = "-c";
            inputs[2] = string(abi.encodePacked("echo \"=== STATE RESET ===\" >> ", LOG_PATH));
            vm.ffi(inputs);
        }
    }

    function _actionTypeToString(ActionType actionType) internal pure returns (string memory) {
        if (actionType == ActionType.Noop) return "Noop";
        if (actionType == ActionType.CreateFlow) return "CreateFlow";
        if (actionType == ActionType.UpdateFlow) return "UpdateFlow";
        if (actionType == ActionType.CfaLiquidate) return "CfaLiquidate";
        if (actionType == ActionType.Distribute) return "Distribute";
        if (actionType == ActionType.DistributeFlow) return "DistributeFlow";
        if (actionType == ActionType.Transfer) return "Transfer";
        if (actionType == ActionType.Approve) return "Approve";
        if (actionType == ActionType.TransferFrom) return "TransferFrom";
        if (actionType == ActionType.TransferAll) return "TransferAll";
        if (actionType == ActionType.IncreaseAllowance) return "IncreaseAllowance";
        if (actionType == ActionType.DecreaseAllowance) return "DecreaseAllowance";
        if (actionType == ActionType.Upgrade) return "Upgrade";
        if (actionType == ActionType.Downgrade) return "Downgrade";
        if (actionType == ActionType.SetFlowPermissions) return "SetFlowPermissions";
        if (actionType == ActionType.SetMaxFlowPermissions) return "SetMaxFlowPermissions";
        if (actionType == ActionType.RevokeFlowPermissions) return "RevokeFlowPermissions";
        if (actionType == ActionType.ConnectPool) return "ConnectPool";
        if (actionType == ActionType.DisconnectPool) return "DisconnectPool";
        if (actionType == ActionType.UpdateMemberUnits) return "UpdateMemberUnits";
        if (actionType == ActionType.ClaimAll) return "ClaimAll";
        if (actionType == ActionType.PoolIncreaseAllowance) return "PoolIncreaseAllowance";
        if (actionType == ActionType.PoolDecreaseAllowance) return "PoolDecreaseAllowance";
        if (actionType == ActionType.PoolApprove) return "PoolApprove";
        if (actionType == ActionType.Revert) return "Revert";
        if (actionType == ActionType.BurnGas) return "BurnGas";
        if (actionType == ActionType.ReturnEmptyCtx) return "ReturnEmptyCtx";
        if (actionType == ActionType.ReturnInvalidCtx) return "ReturnInvalidCtx";
        if (actionType == ActionType.ReturnValidCtx) return "ReturnValidCtx";
        if (actionType == ActionType.CallAnotherApp) return "CallAnotherApp";
        return "Unknown";
    }

    // *** LOGGING BLOCK END ***

    // Clear the action queue
    function clearActionQueue() external {
        delete _actionQueue;
    }

    // Add an action to the queue
    function addAction(ActionType actionType, bytes calldata data) external {
        require(_actionQueue.length < MAX_ACTIONS, "ChaosMonkey: Action queue full");
        _actionQueue.push(Action(actionType, data));
    }

    // Execute actions in the queue, updating ctx
    function _executeActions(bytes memory ctx) private returns (bytes memory newCtx) {
        newCtx = ctx;
       writeSucceededActionBool();
        for (uint256 i = 0; i < _actionQueue.length; i++) {
            fl.log("EXECUTING ACTION", i);
            Action memory action = _actionQueue[i];
            ActionType actionType = action.actionType;

            try this._executeSingleAction(actionType, action.data, newCtx) returns (bytes memory updatedCtx) {
                newCtx = updatedCtx;
                onActionSucceeded(actionType, action.data);
                lcovQueueLength(_actionQueue.length, i, true);
            } catch {
                // If an action reverts, continue to test
                onActionReverted(actionType, action.data);
                lcovQueueLength(_actionQueue.length, i, false);
                writeRevertedActionBool();
                revert("Action reverted");
            }
        }
        // Clear queue after execution
        delete _actionQueue;
        resetFlowState();
        _logStateReset();
        
        return newCtx;
    }

    // Execute a single action, returning updated ctx
    // IMPORTANT: do not delete the fl.log statements, removing could lead to the broken fuzzer conjectures
    function _executeSingleAction(ActionType actionType, bytes memory data, bytes memory ctx)
        external
        returns (bytes memory newCtx)
    {
        require(msg.sender == address(this), "ChaosMonkey: Internal calls only");

        if (actionType == ActionType.Noop) {
            fl.log("_executeSingleActionNoop");
            return ctx;
        } else if (actionType == ActionType.CreateFlow || actionType == ActionType.UpdateFlow) {
            fl.log("_executeSingleActionCreateFlow");
            (address receiver, int96 flowRate) = abi.decode(data, (address, int96));
            return _superToken.flowWithCtx(receiver, flowRate, ctx);
        } else if (actionType == ActionType.CfaLiquidate) {
            (address sender, address receiver) = abi.decode(data, (address, address));
            fl.log("Cfa liquidate");
            return _superToken.deleteFlowWithCtx(sender, receiver, ctx);
        } else if (actionType == ActionType.Distribute) {
            (address poolAddr, uint256 amount) = abi.decode(data, (address, uint256));
            fl.log("Distribute");
            return _superToken.distributeWithCtx(address(this), ISuperfluidPool(poolAddr), amount, ctx);
        } else if (actionType == ActionType.DistributeFlow) {
            (address poolAddr, int96 flowRate) = abi.decode(data, (address, int96));
            fl.log("DistributeFlow");
            return _superToken.distributeFlowWithCtx(address(this), ISuperfluidPool(poolAddr), flowRate, ctx);
        } else if (actionType == ActionType.Transfer) {
            (address recipient, uint256 amount) = abi.decode(data, (address, uint256));
            _superToken.transfer(recipient, amount);
            fl.log("Transfer");
            return ctx;
        } else if (actionType == ActionType.Approve) {
            (address spender, uint256 amount) = abi.decode(data, (address, uint256));
            _superToken.approve(spender, amount);
            fl.log("Approve");
            return ctx;
        } else if (actionType == ActionType.TransferFrom) {
            (address from, address to, uint256 amount) = abi.decode(data, (address, address, uint256));
            _superToken.transferFrom(from, to, amount);
            fl.log("TransferFrom");
            return ctx;
        } else if (actionType == ActionType.TransferAll) {
            address recipient = abi.decode(data, (address));
            _superToken.transferAll(recipient);
            fl.log("TransferAll");
            return ctx;
        } else if (actionType == ActionType.IncreaseAllowance) {
            (address spender, uint256 addedValue) = abi.decode(data, (address, uint256));
            _superToken.increaseAllowance(spender, addedValue);
            fl.log("IncreaseAllowance");
            return ctx;
        } else if (actionType == ActionType.DecreaseAllowance) {
            (address spender, uint256 subtractedValue) = abi.decode(data, (address, uint256));
            _superToken.decreaseAllowance(spender, subtractedValue);
            fl.log("DecreaseAllowance");
            return ctx;
        } else if (actionType == ActionType.Upgrade) {
            uint256 amount = abi.decode(data, (uint256));
            fl.log("Upgrade");
            try _superToken.upgrade(amount) {
                _fuzzer.setExpectedTotalSupply((_fuzzer.getExpectedTotalSupply() + (amount)));
            } catch {}

            return ctx;
        } else if (actionType == ActionType.Downgrade) {
            uint256 amount = abi.decode(data, (uint256));
            try _superToken.downgrade(amount) {
                fl.log("Downgrade");
                _fuzzer.setExpectedTotalSupply((_fuzzer.getExpectedTotalSupply() - (amount)));
            } catch {}

            return ctx;
        } else if (actionType == ActionType.SetFlowPermissions) {
            (address flowOperator, bool allowCreate, bool allowUpdate, bool allowDelete, int96 flowRateAllowance) =
                abi.decode(data, (address, bool, bool, bool, int96));
            fl.log("SetFlowPermissions");
            return _superToken.setFlowPermissionsWithCtx(
                flowOperator, allowCreate, allowUpdate, allowDelete, flowRateAllowance, ctx
            );
            } else if (actionType == ActionType.SetMaxFlowPermissions) {
                address flowOperator = abi.decode(data, (address));
            fl.log("SetMaxFlowPermissions");
            return _superToken.setMaxFlowPermissionsWithCtx(flowOperator, ctx);
        } else if (actionType == ActionType.RevokeFlowPermissions) {
            address flowOperator = abi.decode(data, (address));
            fl.log("RevokeFlowPermissions");
            return _superToken.revokeFlowPermissionsWithCtx(flowOperator, ctx);
        } else if (actionType == ActionType.ConnectPool) {
            address poolAddr = abi.decode(data, (address));
            fl.log("ConnectPool");
            return _superToken.connectPoolWithCtx(ISuperfluidPool(poolAddr), ctx);
        } else if (actionType == ActionType.DisconnectPool) {
            address poolAddr = abi.decode(data, (address));
            fl.log("DisconnectPool");
            return _superToken.disconnectPoolWithCtx(ISuperfluidPool(poolAddr), ctx);
        } else if (actionType == ActionType.UpdateMemberUnits) {
            (address poolAddr, address member, uint128 units) = abi.decode(data, (address, address, uint128));
            ISuperfluidPool(poolAddr).updateMemberUnits(member, units);
            fl.log("UpdateMemberUnits");
            return ctx;
        } else if (actionType == ActionType.ClaimAll) {
            address poolAddr = abi.decode(data, (address));
            fl.log("ClaimAll");
            return _superToken.claimAllWithCtx(ISuperfluidPool(poolAddr), address(this), ctx);
        } else if (actionType == ActionType.PoolIncreaseAllowance) {
            (address poolAddr, address spender, uint256 addedValue) = abi.decode(data, (address, address, uint256));
            ISuperfluidPool(poolAddr).increaseAllowance(spender, addedValue);
            fl.log("PoolIncreaseAllowance");
            return ctx;
        } else if (actionType == ActionType.PoolDecreaseAllowance) {
            (address poolAddr, address spender, uint256 subtractedValue) = abi.decode(data, (address, address, uint256));
            ISuperfluidPool(poolAddr).decreaseAllowance(spender, subtractedValue);
            fl.log("PoolDecreaseAllowance");
            return ctx;
        } else if (actionType == ActionType.PoolApprove) {
            (address poolAddr, address spender, uint256 amount) = abi.decode(data, (address, address, uint256));
            ISuperfluidPool(poolAddr).approve(spender, amount);
            fl.log("PoolApprove");
                return ctx;
        } else if (actionType == ActionType.Revert) {
            fl.log("Revert");
            revert(abi.decode(data, (string)));
        } else if (actionType == ActionType.BurnGas) {
            fl.log("BurnGas");
            _burnGas();
            return ctx;
        } else if (actionType == ActionType.ReturnEmptyCtx) {
            fl.log("ReturnEmptyCtx");
            return new bytes(0);
        } else if (actionType == ActionType.ReturnInvalidCtx) {
            fl.log("ReturnInvalidCtx");
            return new bytes(42);
        } else if (actionType == ActionType.ReturnValidCtx) {
            fl.log("ReturnValidCtx");
                return VALID_CTX; //TODO: Return valid ctx
        } else if (actionType == ActionType.CallAnotherApp) {
            fl.log("CallAnotherApp");
            // Attempt to perform a nested app call by invoking actionNoop on the other app
            bytes memory callData = abi.encodeCall(INoopApp.actionNoop, (new bytes(0)));
            bytes memory newCtxReturned = _host.callAppActionWithContext(_otherApp, callData, ctx);
            return newCtxReturned;
        }
        return ctx;
    }

    // Execute before-callback actions (view only)
    function _executeBeforeAction(bytes calldata ctx) private view returns (bytes memory cbdata) {
          return abi.encode("ChaosMonkey");
    }

    // Burn gas for testing
    function _burnGas() private view {
        // solhint-disable-next-line no-inline-assembly 
        uint256 sum = 0;
        for (uint256 i = 0; i < 1000000000; i++) { 
            sum += i;
        }
    }

    // // ISuperApp Callbacks
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external view override returns (bytes memory cbdata) {
        require(msg.sender == address(_host), "Invalid caller");
        return _executeBeforeAction(ctx);
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        require(msg.sender == address(_host), "Invalid caller");
        _flows[agreementId] = true;

        console.log("_afterAgreementCreated");
        return _executeActions(ctx);
    }

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external view override returns (bytes memory cbdata) {
        require(msg.sender == address(_host), "Invalid caller");
        return _executeBeforeAction(ctx);
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        require(msg.sender == address(_host), "Invalid caller");
        return _executeActions(ctx);
    }

    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external view override returns (bytes memory cbdata) {
        require(msg.sender == address(_host), "Invalid caller");
        return _executeBeforeAction(ctx);
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        require(msg.sender == address(_host), "Invalid caller");
        delete _flows[agreementId];
        return _executeActions(ctx);
    }


    function lcovQueueLength(uint256 length, uint256 index, bool success) internal {
        if (success) {
            if (length > 0 && length <= 2) {
                fl.log("Success: Queue length is between 0 and 2");
                if (index > 0 && index <= 2) {
                    fl.log("Success: Queue index is between 0 and 2");
                }
            } else if (length > 2 && length <= 5) {
                fl.log("Success: Queue length is between 2 and 5");

                if (index > 0 && index <= 2) {
                    fl.log("Success: Queue index is between 0 and 2");
                } else if (index > 2 && index <= 5) {
                    fl.log("Success: Queue index is between 2 and 5");
                }
            } else if (length > 5 && length <= 10) {
                fl.log("Success: Queue length is between 5 and 10");

                if (index > 0 && index <= 2) {
                    fl.log("Success: Queue index is between 0 and 2");
                } else if (index > 2 && index <= 5) {
                    fl.log("Success: Queue index is between 2 and 5");
                } else if (index > 5 && index <= 10) {
                    fl.log("Success: Queue index is between 5 and 10");
                }
            } else {
                fl.log("Success: Queue length is greater than 10");
            }
        } else {
            if (length > 0 && length <= 2) {
                fl.log("Failure: Queue length is between 0 and 2");
                if (index > 0 && index <= 2) {
                    fl.log("Failure: Queue index is between 0 and 2");
                }
            } else if (length > 2 && length <= 5) {
                fl.log("Failure: Queue length is between 2 and 5");
                if (index > 0 && index <= 2) {
                    fl.log("Failure: Queue index is between 0 and 2");
                } else if (index > 2 && index <= 5) {
                    fl.log("Failure: Queue index is between 2 and 5");
                }
            } else if (length > 5 && length <= 10) {
                fl.log("Failure: Queue length is between 5 and 10");
                if (index > 0 && index <= 2) {
                    fl.log("Failure: Queue index is between 0 and 2");
                } else if (index > 2 && index <= 5) {
                    fl.log("Failure: Queue index is between 2 and 5");
                } else if (index > 5 && index <= 10) {
                    fl.log("Failure: Queue index is between 5 and 10");
                }
            } else {
                fl.log("Failure: Queue length is greater than 10");
            }
        }
    }

    function upgradeSuperToken(uint256 amount) public {
        _token.approve(address(_superToken), amount);
        _superToken.upgrade(amount);
    }
}

interface INoopApp {
    function actionNoop(bytes calldata ctx) external returns (bytes memory newCtx);
}
