import { expect } from "chai";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  computeStatsCommitment,
  generateProof,
  verifyProofJS,
  computeStats,
  BASE_STATS,
} from "../fixtures/GameFixture";

describe("CombatReveal Circuit", function () {
  this.timeout(180000);

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  // Helper to prove combat reveal
  async function proveCombatReveal(
    x: bigint,
    y: bigint,
    salt: bigint,
    playerSalt: bigint,
    artifactIds: number[],
    gameId: bigint
  ) {
    const commitment = await computePositionCommitment(x, y, salt);
    const stats = computeStats(artifactIds);
    const statsCommitment = await computeStatsCommitment(
      BigInt(stats.hp),
      BigInt(stats.atk),
      BigInt(stats.def),
      playerSalt
    );

    // Pad artifacts to 8 slots
    const paddedArtifacts = [...artifactIds, ...Array(8 - artifactIds.length).fill(0)].slice(0, 8);

    return generateProof("combat_reveal", {
      x: x.toString(),
      y: y.toString(),
      salt: salt.toString(),
      player_salt: playerSalt.toString(),
      artifact_ids: paddedArtifacts.map(String),
      commitment,
      stats_commitment: statsCommitment,
      game_id: gameId.toString(),
    });
  }

  describe("Base stats (no artifacts)", () => {
    it("proves base stats: HP=100, ATK=10, DEF=5", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        5n, 5n, 111n, 999n,
        [], // No artifacts
        1n
      );

      expect(publicInputs).to.have.length(3);
      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });

  describe("Single artifact bonuses", () => {
    it("Shadow Blade (ID 1): +5 ATK → ATK=15", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        3n, 7n, 222n, 888n,
        [1], // Shadow Blade
        42n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("Iron Aegis (ID 2): +5 DEF → DEF=10", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        1n, 1n, 333n, 777n,
        [2],
        10n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("Vitality Amulet (ID 3): +20 HP → HP=120", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        1n, 1n, 500n, 600n,
        [3],
        10n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("Berserker Helm (ID 4): +8 ATK, -2 DEF → ATK=18, DEF=3", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        8n, 2n, 300n, 400n,
        [4],
        5n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("Phantom Cloak (ID 5): +10 HP, -1 ATK, +7 DEF", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        6n, 6n, 550n, 660n,
        [5],
        20n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("Blood Crystal (ID 7): +6 ATK, -10 HP → HP=90, ATK=16", async () => {
      const { proof, publicInputs } = await proveCombatReveal(
        12n, 4n, 700n, 800n,
        [7],
        15n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });

  describe("Multiple artifacts", () => {
    it("5 artifacts stacking bonuses", async () => {
      // Shadow Blade (1) + Iron Aegis (2) + Vitality Amulet (3) + War Gauntlets (6) + Soul Vessel (8)
      const artifacts = [1, 2, 3, 6, 8];
      const stats = computeStats(artifacts);
      
      expect(stats.hp).to.equal(135);  // 100 + 0 + 0 + 20 + 0 + 15
      expect(stats.atk).to.equal(20);  // 10 + 5 + 0 + 0 + 3 + 2
      expect(stats.def).to.equal(15);  // 5 + 0 + 5 + 0 + 3 + 2

      const { proof, publicInputs } = await proveCombatReveal(
        10n, 2n, 333n, 777n,
        artifacts,
        7n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("all 8 artifacts", async () => {
      const artifacts = [1, 2, 3, 4, 5, 6, 7, 8];
      const stats = computeStats(artifacts);
      
      expect(stats.hp).to.equal(135);  // 100 + 45 - 10
      expect(stats.atk).to.equal(33);  // 10 + 24 - 1
      expect(stats.def).to.equal(20);  // 5 + 17 - 2

      const { proof, publicInputs } = await proveCombatReveal(
        0n, 0n, 999n, 111n,
        artifacts,
        99n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("duplicate artifacts allowed", async () => {
      // Two Shadow Blades
      const artifacts = [1, 1];
      const stats = computeStats(artifacts);
      
      expect(stats.atk).to.equal(20); // 10 + 5 + 5

      const { proof, publicInputs } = await proveCombatReveal(
        0n, 0n, 444n, 666n,
        artifacts,
        3n
      );

      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });

  describe("Invalid proofs", () => {
    it("fails with wrong stats commitment (lying about stats)", async () => {
      const commitment = await computePositionCommitment(5n, 5n, 111n);
      // Claim base stats but actually have Shadow Blade
      const wrongStatsCommitment = await computeStatsCommitment(100n, 10n, 5n, 999n);

      try {
        await generateProof("combat_reveal", {
          x: "5",
          y: "5",
          salt: "111",
          player_salt: "999",
          artifact_ids: ["1", "0", "0", "0", "0", "0", "0", "0"], // Has Shadow Blade
          commitment,
          stats_commitment: wrongStatsCommitment, // Claims base stats
          game_id: "1",
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("Stats commitment mismatch");
      }
    });

    it("fails with wrong position commitment", async () => {
      const statsCommitment = await computeStatsCommitment(100n, 10n, 5n, 999n);

      try {
        await generateProof("combat_reveal", {
          x: "5",
          y: "5",
          salt: "111",
          player_salt: "999",
          artifact_ids: ["0", "0", "0", "0", "0", "0", "0", "0"],
          commitment: "0x" + "00".repeat(32), // Wrong
          stats_commitment: statsCommitment,
          game_id: "1",
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("Position commitment mismatch");
      }
    });

    it("fails with game_id = 0", async () => {
      try {
        await proveCombatReveal(5n, 5n, 111n, 999n, [], 0n);
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("Invalid game ID");
      }
    });

    it("fails with invalid artifact ID (> 8)", async () => {
      const commitment = await computePositionCommitment(5n, 5n, 111n);
      const statsCommitment = await computeStatsCommitment(100n, 10n, 5n, 999n);

      try {
        await generateProof("combat_reveal", {
          x: "5",
          y: "5",
          salt: "111",
          player_salt: "999",
          artifact_ids: ["99", "0", "0", "0", "0", "0", "0", "0"], // Invalid
          commitment,
          stats_commitment: statsCommitment,
          game_id: "1",
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("Invalid artifact ID");
      }
    });
  });
});
