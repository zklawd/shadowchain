// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IShadowVerifier} from "./interfaces/IShadowVerifier.sol";

/// @title MockVerifier
/// @notice Always-true verifier for development and testing.
///         Replace with actual Noir-generated verifiers before production.
contract MockVerifier is IShadowVerifier {
    function verify(
        bytes calldata,
        bytes32[] calldata
    ) external pure override returns (bool) {
        return true;
    }
}

/// @title RejectVerifier
/// @notice Always-false verifier for negative testing.
contract RejectVerifier is IShadowVerifier {
    function verify(
        bytes calldata,
        bytes32[] calldata
    ) external pure override returns (bool) {
        return false;
    }
}
