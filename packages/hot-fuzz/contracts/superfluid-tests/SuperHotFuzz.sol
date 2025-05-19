// // SPDX-License-Identifier: AGPLv3
// pragma solidity >= 0.8.0;

// import "./ConstantFlowAgreementV1.hott.sol";
// import "./GeneralDistributionAgreementV1.hott.sol";
// import "./SuperToken.hott.sol";
// import "./ChaosMonkeySuperApp.hott.sol";
// import "@perimetersec/fuzzlib/src/FuzzBase.sol";

// // Combine all the hot fuzzes
// contract SuperHotFuzz is CFAHotFuzzMixin, GDAHotFuzzMixin, SuperTokenHotFuzzMixin, SuperAppHotFuzzMixin {
//     constructor() {
//         _initTesters();
//     }
// }

pragma solidity >= 0.8.0;

import "./ChaosMonkeySuperApp.hott.sol";
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

// Combine all the hot fuzzes
contract SuperHotFuzz is SuperAppHotFuzzMixin {
    constructor() {
        _initTesters();
        _initChaosMonkey();
    }
}
