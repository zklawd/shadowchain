// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ShadowChainGame} from "../src/ShadowChainGame.sol";
import {ArtifactRegistry} from "../src/ArtifactRegistry.sol";
import {PositionCommitHonkVerifier} from "../src/verifiers/position_commit_verifier.sol";
import {ValidMoveHonkVerifier} from "../src/verifiers/valid_move_verifier.sol";
import {ClaimArtifactHonkVerifier} from "../src/verifiers/claim_artifact_verifier.sol";
import {CombatRevealHonkVerifier} from "../src/verifiers/combat_reveal_verifier.sol";

/// @title Deploy ShadowChain to Sepolia
/// @notice Deploys all contracts: verifiers, artifact registry, and main game
///
/// Usage:
///   forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC --account zklawd --broadcast -vvvv
contract DeployShadowChain is Script {
    function run() external {
        vm.startBroadcast();

        // 1. Deploy verifiers
        console.log("Deploying verifiers...");
        PositionCommitHonkVerifier positionVerifier = new PositionCommitHonkVerifier();
        console.log("  PositionCommit verifier:", address(positionVerifier));

        ValidMoveHonkVerifier moveVerifier = new ValidMoveHonkVerifier();
        console.log("  ValidMove verifier:", address(moveVerifier));

        ClaimArtifactHonkVerifier artifactVerifier = new ClaimArtifactHonkVerifier();
        console.log("  ClaimArtifact verifier:", address(artifactVerifier));

        CombatRevealHonkVerifier combatVerifier = new CombatRevealHonkVerifier();
        console.log("  CombatReveal verifier:", address(combatVerifier));

        // 2. Deploy artifact registry
        console.log("Deploying ArtifactRegistry...");
        ArtifactRegistry artifactRegistry = new ArtifactRegistry();
        console.log("  ArtifactRegistry:", address(artifactRegistry));

        // 3. Deploy main game contract
        // Note: ShadowChainGame constructor expects IShadowVerifier interfaces.
        // The HonkVerifier contracts implement IVerifier with the same signature,
        // so we pass them directly.
        console.log("Deploying ShadowChainGame...");
        ShadowChainGame game = new ShadowChainGame(
            address(moveVerifier),
            address(artifactVerifier),
            address(combatVerifier),
            address(artifactRegistry)
        );
        console.log("  ShadowChainGame:", address(game));

        vm.stopBroadcast();

        console.log("");
        console.log("=== ShadowChain Deployed ===");
        console.log("Game contract:", address(game));
        console.log("Move verifier:", address(moveVerifier));
        console.log("Artifact verifier:", address(artifactVerifier));
        console.log("Combat verifier:", address(combatVerifier));
        console.log("Artifact registry:", address(artifactRegistry));
    }
}
