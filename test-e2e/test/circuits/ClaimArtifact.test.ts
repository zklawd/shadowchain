import { expect } from "chai";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  computeCellHash,
  generateProof,
  verifyProofJS,
} from "../fixtures/GameFixture";

describe("ClaimArtifact Circuit", function () {
  this.timeout(120000);

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  // Helper to prove artifact claim
  async function proveArtifactClaim(
    x: bigint,
    y: bigint,
    salt: bigint,
    artifactId: bigint
  ) {
    const commitment = await computePositionCommitment(x, y, salt);
    const cellHash = await computeCellHash(x, y);

    return generateProof("claim_artifact", {
      x: x.toString(),
      y: y.toString(),
      salt: salt.toString(),
      commitment,
      artifact_cell_hash: cellHash,
      artifact_id: artifactId.toString(),
    });
  }

  describe("Valid claims", () => {
    it("claims artifact ID 1 at (10, 3)", async () => {
      const { proof, publicInputs } = await proveArtifactClaim(10n, 3n, 42n, 1n);
      
      expect(publicInputs).to.have.length(3);
      const verified = await verifyProofJS("claim_artifact", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("claims artifact ID 5 at (7, 12)", async () => {
      const { proof, publicInputs } = await proveArtifactClaim(7n, 12n, 9999n, 5n);
      const verified = await verifyProofJS("claim_artifact", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("claims at boundary (0, 15)", async () => {
      const { proof, publicInputs } = await proveArtifactClaim(0n, 15n, 777n, 3n);
      const verified = await verifyProofJS("claim_artifact", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("claims all artifact IDs (1-8)", async () => {
      for (let id = 1n; id <= 8n; id++) {
        const { proof, publicInputs } = await proveArtifactClaim(
          id % 16n,
          (id * 2n) % 16n,
          id * 100n,
          id
        );
        const verified = await verifyProofJS("claim_artifact", proof, publicInputs);
        expect(verified).to.be.true;
      }
    });
  });

  describe("Invalid claims", () => {
    it("fails with wrong cell hash (player not at artifact)", async () => {
      const commitment = await computePositionCommitment(10n, 3n, 42n);
      const wrongCellHash = await computeCellHash(5n, 5n); // Wrong cell

      try {
        await generateProof("claim_artifact", {
          x: "10",
          y: "3",
          salt: "42",
          commitment,
          artifact_cell_hash: wrongCellHash,
          artifact_id: "1",
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("not at artifact cell");
      }
    });

    it("fails with wrong position commitment", async () => {
      const cellHash = await computeCellHash(10n, 3n);

      try {
        await generateProof("claim_artifact", {
          x: "10",
          y: "3",
          salt: "42",
          commitment: "0x" + "00".repeat(32), // Wrong
          artifact_cell_hash: cellHash,
          artifact_id: "1",
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("commitment mismatch");
      }
    });

    it("fails with artifact ID 0", async () => {
      try {
        await proveArtifactClaim(10n, 3n, 42n, 0n);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("Invalid artifact ID");
      }
    });

    it("fails with artifact ID > 8", async () => {
      try {
        await proveArtifactClaim(10n, 3n, 42n, 99n);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("out of range");
      }
    });
  });
});
