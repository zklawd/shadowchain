import { expect } from "chai";
import { ethers } from "hardhat";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  generateProof,
  verifyProofJS,
  emptyWalls,
} from "../fixtures/GameFixture";

describe("ValidMove Circuit", function () {
  this.timeout(180000);

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  // Helper to generate valid move proof
  async function proveMove(
    oldX: bigint,
    oldY: bigint,
    oldSalt: bigint,
    newX: bigint,
    newY: bigint,
    newSalt: bigint,
    walls: string[] = emptyWalls()
  ) {
    const oldCommitment = await computePositionCommitment(oldX, oldY, oldSalt);
    const newCommitment = await computePositionCommitment(newX, newY, newSalt);

    return generateProof("valid_move", {
      old_x: oldX.toString(),
      old_y: oldY.toString(),
      old_salt: oldSalt.toString(),
      new_x: newX.toString(),
      new_y: newY.toString(),
      new_salt: newSalt.toString(),
      old_commitment: oldCommitment,
      new_commitment: newCommitment,
      map_walls: walls,
    });
  }

  describe("Valid moves", () => {
    it("proves move NORTH (y decreases)", async () => {
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 5n, 4n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves move SOUTH (y increases)", async () => {
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 5n, 6n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves move EAST (x increases)", async () => {
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 6n, 5n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves move WEST (x decreases)", async () => {
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 4n, 5n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves STAY (same position, new salt)", async () => {
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 5n, 5n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves move at boundary (0,0 → 1,0)", async () => {
      const { proof, publicInputs } = await proveMove(0n, 0n, 111n, 1n, 0n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves move at max boundary (15,15 → 14,15)", async () => {
      const { proof, publicInputs } = await proveMove(15n, 15n, 111n, 14n, 15n, 222n);
      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });

  describe("Invalid moves", () => {
    it("fails diagonal move", async () => {
      try {
        await proveMove(5n, 5n, 111n, 6n, 6n, 222n);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("not adjacent");
      }
    });

    it("fails teleport (distance > 1)", async () => {
      try {
        await proveMove(0n, 0n, 111n, 10n, 10n, 222n);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("not adjacent");
      }
    });

    it("fails move into wall", async () => {
      // Wall at (6, 5): row 5, bit 6 = 0b01000000 = 64
      const walls = emptyWalls();
      walls[5] = "64";

      try {
        await proveMove(5n, 5n, 111n, 6n, 5n, 222n, walls);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("wall");
      }
    });

    it("fails with wrong old commitment", async () => {
      const newCommitment = await computePositionCommitment(6n, 5n, 222n);

      try {
        await generateProof("valid_move", {
          old_x: "5",
          old_y: "5",
          old_salt: "111",
          new_x: "6",
          new_y: "5",
          new_salt: "222",
          old_commitment: "0x" + "00".repeat(32), // Wrong
          new_commitment: newCommitment,
          map_walls: emptyWalls(),
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("commitment mismatch");
      }
    });
  });

  describe("On-chain verification", () => {
    it("verifies valid move proof on-chain", async () => {
      // Deploy verifier
      const ValidMoveTest = await ethers.getContractFactory("ValidMoveTest");
      const contract = await ValidMoveTest.deploy();
      await contract.waitForDeployment();

      // Generate proof
      const { proof, publicInputs } = await proveMove(5n, 5n, 111n, 6n, 5n, 222n);

      // Verify on-chain
      const result = await contract.verifyMove(proof, publicInputs);
      expect(result).to.be.true;
    });
  });
});
