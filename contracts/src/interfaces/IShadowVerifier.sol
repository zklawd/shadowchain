// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IShadowVerifier
/// @notice Interface for Noir ZK proof verifiers.
///         Each circuit (valid_move, claim_artifact, combat_reveal, encounter_check)
///         has a verifier that implements this interface.
///         Placeholder implementations will be replaced with actual Noir-generated
///         verifiers (UltraPlonk) once the circuits are compiled.
interface IShadowVerifier {
    /// @notice Verify a ZK proof against its public inputs
    /// @param proof The serialized proof bytes from the Noir prover
    /// @param publicInputs The public inputs to the circuit
    /// @return True if the proof is valid, false otherwise
    function verify(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external view returns (bool);
}
