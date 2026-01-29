import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("PositionCommit E2E", function () {
  this.timeout(120000);

  it("generates and verifies a position commitment proof", async function () {
    // Initialize Barretenberg for Pedersen hash
    console.log("Initializing Barretenberg...");
    const { Barretenberg, Fr } = await import("@aztec/bb.js");
    const bb = await Barretenberg.new();

    const x = 7n;
    const y = 12n;
    const salt = 999n;

    // Helper to convert bigint to Fr
    const toFr = (n: bigint) => {
      const hex = n.toString(16).padStart(64, "0");
      return Fr.fromBuffer(Buffer.from(hex, "hex"));
    };

    // Compute commitment
    console.log("Computing commitment...");
    const commitmentFr = await bb.pedersenHash([toFr(x), toFr(y), toFr(salt)], 0);
    const commitment = "0x" + Buffer.from(commitmentFr.toBuffer()).toString("hex");
    console.log("Commitment:", commitment);

    // Load circuit
    console.log("Loading circuit...");
    const { noir, backend } = await hre.noir.getCircuit("position_commit");

    // Circuit inputs
    const input = {
      x: x.toString(),
      y: y.toString(),
      salt: salt.toString(),
      commitment: commitment,
    };

    console.log("Generating witness...");
    const { witness } = await noir.execute(input);

    console.log("Generating proof...");
    const { proof, publicInputs } = await backend.generateProof(witness, {
      keccak: true,
    });
    console.log("Proof size:", proof.length, "bytes");
    console.log("Public inputs:", publicInputs.length);

    // Verify in JS
    console.log("Verifying in JS...");
    const jsResult = await backend.verifyProof(
      { proof, publicInputs },
      { keccak: true }
    );
    expect(jsResult).to.eq(true);
    console.log("✅ Position commitment proof verified!");

    await bb.destroy();
  });
});
