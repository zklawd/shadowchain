import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("ValidMove E2E", function () {
  // Increase timeout for proof generation
  this.timeout(300000);

  it("generates and verifies a valid move proof on-chain", async function () {
    console.log("Deploying verifier contract...");
    
    // Deploy verifier contract
    const ValidMoveTest = await ethers.getContractFactory("ValidMoveTest");
    const contract = await ValidMoveTest.deploy();
    await contract.waitForDeployment();
    console.log("Contract deployed at:", await contract.getAddress());

    // Initialize Barretenberg for Pedersen hash
    console.log("Initializing Barretenberg...");
    const { Barretenberg, Fr } = await import("@aztec/bb.js");
    const bb = await Barretenberg.new();
    console.log("Barretenberg initialized");

    // Get the circuit from hardhat-noir
    console.log("Loading circuit...");
    const { noir, backend } = await hre.noir.getCircuit("valid_move");
    console.log("Circuit loaded");

    // Test inputs: move from (5,5) to (6,5) (east)
    const oldX = 5n;
    const oldY = 5n;
    const oldSalt = 111n;
    const newX = 6n;
    const newY = 5n;
    const newSalt = 222n;

    // Helper to convert bigint to Fr
    const toFr = (n: bigint): typeof Fr => {
      const hex = n.toString(16).padStart(64, "0");
      const buffer = Buffer.from(hex, "hex");
      return Fr.fromBuffer(buffer);
    };

    // Compute Pedersen commitments (matches Noir's std::hash::pedersen_hash)
    console.log("Computing commitments...");
    const oldCommitmentFr = await bb.pedersenHash(
      [toFr(oldX), toFr(oldY), toFr(oldSalt)],
      0
    );
    const newCommitmentFr = await bb.pedersenHash(
      [toFr(newX), toFr(newY), toFr(newSalt)],
      0
    );

    const oldCommitment = "0x" + Buffer.from(oldCommitmentFr.toBuffer()).toString("hex");
    const newCommitment = "0x" + Buffer.from(newCommitmentFr.toBuffer()).toString("hex");
    
    console.log("Old commitment:", oldCommitment);
    console.log("New commitment:", newCommitment);

    // Prepare circuit inputs
    const input = {
      // Private inputs
      old_x: oldX.toString(),
      old_y: oldY.toString(),
      old_salt: oldSalt.toString(),
      new_x: newX.toString(),
      new_y: newY.toString(),
      new_salt: newSalt.toString(),
      // Public inputs
      old_commitment: oldCommitment,
      new_commitment: newCommitment,
      map_walls: Array(16).fill("0"),
    };

    // Generate witness
    console.log("Generating witness...");
    const { witness } = await noir.execute(input);
    console.log("Witness generated");

    // Generate proof with keccak (CRITICAL for on-chain verification!)
    console.log("Generating proof (this may take 1-2 minutes)...");
    const startProof = Date.now();
    const { proof, publicInputs } = await backend.generateProof(witness, {
      keccak: true,
    });
    console.log(`Proof generated in ${(Date.now() - startProof) / 1000}s`);
    console.log("Proof size:", proof.length, "bytes");
    console.log("Public inputs count:", publicInputs.length);

    // Verify in JS first (sanity check)
    console.log("Verifying in JS...");
    const jsResult = await backend.verifyProof(
      { proof, publicInputs },
      { keccak: true }
    );
    expect(jsResult).to.eq(true);
    console.log("✅ JS verification passed!");

    // Verify on-chain
    console.log("Verifying on-chain...");
    const result = await contract.verifyMove(proof, publicInputs as `0x${string}`[]);
    
    expect(result).to.eq(true);
    console.log("✅ On-chain verification passed!");
    
    // Cleanup
    await bb.destroy();
  });

  it("rejects invalid proofs", async function () {
    const ValidMoveTest = await ethers.getContractFactory("ValidMoveTest");
    const contract = await ValidMoveTest.deploy();
    await contract.waitForDeployment();

    // Try to verify with garbage proof
    const fakeProof = "0x" + "00".repeat(100);
    const fakeInputs = Array(34).fill("0x" + "00".repeat(32)) as `0x${string}`[];

    // Should revert
    await expect(
      contract.verifyMove(fakeProof as `0x${string}`, fakeInputs)
    ).to.be.reverted;
    console.log("✅ Invalid proof correctly rejected");
  });
});
