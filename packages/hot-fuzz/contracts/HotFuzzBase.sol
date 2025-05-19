// SPDX-License-Identifier: AGPLv3
// solhint-disable reason-string
// solhint-disable func-name-mixedcase
pragma solidity >= 0.8.0;

import {TestToken} from "@superfluid-finance/ethereum-contracts/contracts/utils/TestToken.sol";
import {ISuperfluid, Superfluid} from "@superfluid-finance/ethereum-contracts/contracts/superfluid/Superfluid.sol";
import {SuperToken} from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import {ConstantFlowAgreementV1} from
    "@superfluid-finance/ethereum-contracts/contracts/agreements/ConstantFlowAgreementV1.sol";
import {SuperfluidFrameworkDeployer} from
    "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.t.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

import {IERC20, ISuperToken, IConstantFlowAgreementV1, SuperfluidTester} from "./SuperfluidTester.sol";
import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "@perimetersec/fuzzlib/src/IHevm.sol";
import "./superfluid-tests/FuzzConstants.sol";
import {ISuperfluidPool} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/ISuperfluidPool.sol";

import {ChaosMonkeySuperApp} from "./superfluid-tests/SuperApps/ChaosMonkeySuperApp.sol";
import {SuperAppMock} from "@superfluid-finance/ethereum-contracts/contracts/mocks/SuperAppMocks.t.sol";
import {SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HotFuzzBase is FuzzBase, FuzzConstants, Test {
    using SuperTokenV1Library for SuperToken;
    // constants

    uint256 private constant INIT_TOKEN_BALANCE = type(uint160).max;
    uint256 private constant INIT_SUPER_TOKEN_BALANCE = type(uint128).max;

    // immutables
    SuperfluidFrameworkDeployer internal immutable _sfDeployer;
    TestToken internal immutable token;
    SuperToken internal immutable superToken;
    uint256 internal immutable nTesters;
    ChaosMonkeySuperApp internal chaosMonkey;
    bool internal cmRevertedThisQueue;
    SuperfluidFrameworkDeployer.Framework internal sf;

    // test states
    SuperfluidTester[] internal testers;
    address[] internal otherAccounts;
    uint256 internal expectedTotalSupply = 0;
    bool internal liquidationFails;
    ISuperfluidPool[] public pools;

    event DebugLogInt(string name, int256 value);

    constructor() {
        _sfDeployer = new SuperfluidFrameworkDeployer();
        _sfDeployer.deployTestFramework();
        sf = _sfDeployer.getFramework();

        // sf = Framework({
        //     governance: testGovernance,
        //     host: host,
        //     cfa: cfaV1,
        //     ida: idaV1,
        //     gda: gdaV1,
        //     superTokenFactory: superTokenFactory,
        //     superTokenLogic: superTokenLogic,
        //     resolver: testResolver,
        //     superfluidLoader: superfluidLoader,
        //     cfaV1Forwarder: cfaV1Forwarder,
        //     gdaV1Forwarder: gdaV1Forwarder,
        //     macroForwarder: macroForwarder,
        //     batchLiquidator: batchLiquidator,
        //     toga: toga
        // });

        (token, superToken) =
            _sfDeployer.deployWrapperSuperToken("HOTFuzz Token", "HOTT", 18, type(uint256).max, address(0));
        nTesters = 10;
        otherAccounts = new address[](0);

        _addAccount(address(sf.gda));
        _addAccount(address(sf.toga));
    }

    function _initTesters() internal virtual {
        testers = new SuperfluidTester[](nTesters);
        for (uint256 i = 0; i < nTesters; ++i) {
            testers[i] = _createTester();
            token.mint(address(testers[i]), INIT_TOKEN_BALANCE);
            testers[i].upgradeSuperToken(INIT_SUPER_TOKEN_BALANCE);
            expectedTotalSupply += INIT_SUPER_TOKEN_BALANCE;
        }
    }

    function _initChaosMonkey() internal {
        chaosMonkey = new ChaosMonkeySuperApp(
            sf.host,
            sf.cfa,
            token,
            superToken,
            testers,
            new SuperAppMock(sf.host, SuperAppDefinitions.APP_LEVEL_FINAL, false),
            address(this)
        );
        _addAccount(address(chaosMonkey));
        token.mint(address(chaosMonkey), INIT_TOKEN_BALANCE);
        chaosMonkey.upgradeSuperToken(INIT_SUPER_TOKEN_BALANCE);
        expectedTotalSupply += INIT_SUPER_TOKEN_BALANCE;
    }

    /**
     *
     * IHotFuzz implementation
     *
     */
    function _createTester() internal virtual returns (SuperfluidTester) {
        return new SuperfluidTester(sf, token, superToken);
    }

    function _addAccount(address a) internal {
        otherAccounts.push(a);
    }

    function _listAccounts() internal view returns (address[] memory accounts) {
        accounts = new address[](_numAccounts());
        for (uint256 i = 0; i < nTesters; ++i) {
            accounts[i] = address(testers[i]);
        }
        for (uint256 i = 0; i < otherAccounts.length; ++i) {
            accounts[i + nTesters] = otherAccounts[i];
        }
    }

    function _numAccounts() internal view returns (uint256) {
        return nTesters + otherAccounts.length;
    }

    function _getOneTester(uint8 a) internal view returns (SuperfluidTester tester) {
        tester = testers[a % _numAccounts()];
    }

    /// @dev The testers returned may be the same
    function _getTwoTesters(uint8 a, uint8 b)
        internal
        view
        returns (SuperfluidTester testerA, SuperfluidTester testerB)
    {
        testerA = _getOneTester(a);
        testerB = _getOneTester(b);
    }

    /// @dev The testers returned may be the same
    function _getThreeTesters(uint8 a, uint8 b, uint8 c)
        internal
        view
        returns (SuperfluidTester testerA, SuperfluidTester testerB, SuperfluidTester testerC)
    {
        testerA = _getOneTester(a);
        testerB = _getOneTester(b);
        testerC = _getOneTester(c);
    }

    function _superTokenBalanceOfNow(address a) internal view returns (int256 avb) {
        (avb,,,) = superToken.realtimeBalanceOfNow(a);
    }

    function setExpectedTotalSupply(uint256 _expectedTotalSupply) public {
        require(msg.sender == address(chaosMonkey), "Only chaosMonkey can call this function");
        expectedTotalSupply = _expectedTotalSupply;
    }

    function getExpectedTotalSupply() public view returns (uint256) {
        return expectedTotalSupply;
    }

    /**
     *
     * Invariants
     *
     */
    function echidna_check_total_supply() public returns (bool) {
        assert(superToken.totalSupply() == expectedTotalSupply);
        return superToken.totalSupply() == expectedTotalSupply;
    }

    function echidna_check_liquiditySumInvariance() public returns (bool) {
        int256 liquiditySum = 0;
        address[] memory accounts = _listAccounts();
        for (uint256 i = 0; i < accounts.length; ++i) {
            (int256 avb, uint256 d, uint256 od,) = superToken.realtimeBalanceOfNow(accounts[i]);
            // FIXME: correct formula
            // liquiditySum += avb + int256(d) - int256(od);
            // current faulty one
            liquiditySum += avb + (d > od ? int256(d) - int256(od) : int256(0));
        }
        emit DebugLogInt("echidna_check_liquiditySumInvariance:liquiditySum", liquiditySum);
        emit DebugLogInt("echidna_check_liquiditySumInvariance:expectedTotalSupply", int256(expectedTotalSupply));
        assert(int256(expectedTotalSupply) == liquiditySum);
        return int256(expectedTotalSupply) == liquiditySum;
    }

    function echidna_check_netFlowRateSumInvariant() public returns (bool) {
        int96 netFlowRateSum = 0;
        address[] memory accounts = _listAccounts();
        for (uint256 i = 0; i < accounts.length; ++i) {
            netFlowRateSum += superToken.getNetFlowRate(accounts[i]);
        }
        emit DebugLogInt("echidna_check_netFlowRateSumInvariant:netFlowRateSum", netFlowRateSum);

        assert(netFlowRateSum == 0);
        return netFlowRateSum == 0;
    }

    function echidna_check_validLiquidationNeverRevertsInvariant() public returns (bool) {
        bool liquidationNeverFails = !liquidationFails;
        assert(liquidationNeverFails);
        return liquidationNeverFails;
    }
}
