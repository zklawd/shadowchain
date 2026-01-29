import { expect } from "chai";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  generateProof,
  verifyProofJS,
} from "../fixtures/GameFixture";

describe("PositionCommit Circuit", function () {
  this.timeout(120000);

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  describe("Valid commitments", () => {
    it("proves knowledge of position (5, 5)", async () => {
      const x = 5n;
      const y = 5n;
      const salt = 12345n;
      const commitment = await computePositionCommitment(x, y, salt);

      const { proof, publicInputs } = await generateProof("position_commit", {
        x: x.toString(),
        y: y.toString(),
        salt: salt.toString(),
        commitment,
      });

      expect(publicInputs).to.have.length(1);
      const verified = await verifyProofJS("position_commit", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves boundary position (0, 0)", async () => {
      const x = 0n;
      const y = 0n;
      const salt = 999n;
      const commitment = await computePositionCommitment(x, y, salt);

      const { proof, publicInputs } = await generateProof("position_commit", {
        x: x.toString(),
        y: y.toString(),
        salt: salt.toString(),
        commitment,
      });

      const verified = await verifyProofJS("position_commit", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("proves boundary position (15, 15)", async () => {
      const x = 15n;
      const y = 15n;
      const salt = 888n;
      const commitment = await computePositionCommitment(x, y, salt);

      const { proof, publicInputs } = await generateProof("position_commit", {
        x: x.toString(),
        y: y.toString(),
        salt: salt.toString(),
        commitment,
      });

      const verified = await verifyProofJS("position_commit", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("different salts produce different commitments", async () => {
      const x = 7n;
      const y = 3n;
      
      const commitment1 = await computePositionCommitment(x, y, 111n);
      const commitment2 = await computePositionCommitment(x, y, 222n);
      
      expect(commitment1).to.not.equal(commitment2);
    });
  });

  describe("Invalid commitments", () => {
    it("fails with wrong commitment", async () => {
      const x = 5n;
      const y = 5n;
      const salt = 12345n;
      const wrongCommitment = "0x" + "00".repeat(32);

      try {
        await generateProof("position_commit", {
          x: x.toString(),
          y: y.toString(),
          salt: salt.toString(),
          commitment: wrongCommitment,
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("commitment mismatch");
      }
    });

    it("fails with wrong position", async () => {
      const commitment = await computePositionCommitment(5n, 5n, 12345n);

      try {
        await generateProof("position_commit", {
          x: "6", // Wrong x
          y: "5",
          salt: "12345",
          commitment,
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("commitment mismatch");
      }
    });

    it("fails with wrong salt", async () => {
      const commitment = await computePositionCommitment(5n, 5n, 12345n);

      try {
        await generateProof("position_commit", {
          x: "5",
          y: "5",
          salt: "99999", // Wrong salt
          commitment,
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("commitment mismatch");
      }
    });
  });
});
