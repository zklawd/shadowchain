import { expect } from "chai";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  computeStatsCommitment,
  generateProof,
  verifyProofJS,
  computeStats,
  ARTIFACT_STATS,
  BASE_STATS,
} from "../fixtures/GameFixture";

describe("Stats Computation Fuzz Tests", function () {
  this.timeout(600000); // 10 minutes for fuzz tests

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  // Random number generator with seed for reproducibility
  function seededRandom(seed: number) {
    return function() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    };
  }

  // Generate random artifact loadout
  function randomArtifacts(rng: () => number, count: number): number[] {
    const artifacts: number[] = [];
    for (let i = 0; i < count; i++) {
      // Random artifact ID 0-8 (0 = empty, 1-8 = artifacts)
      artifacts.push(Math.floor(rng() * 9));
    }
    return artifacts;
  }

  describe("Invariants", () => {
    it("HP is always >= 1 regardless of artifacts", async () => {
      // Blood Crystal gives -10 HP, stack 8 of them
      const artifacts = [7, 7, 7, 7, 7, 7, 7, 7];
      const stats = computeStats(artifacts);
      
      // Even with -80 HP, should floor at 1
      expect(stats.hp).to.be.gte(1);
    });

    it("ATK is always >= 1 regardless of artifacts", async () => {
      // Phantom Cloak gives -1 ATK, stack 8 of them
      const artifacts = [5, 5, 5, 5, 5, 5, 5, 5];
      const stats = computeStats(artifacts);
      
      // Even with -8 ATK, should floor at 1
      expect(stats.atk).to.be.gte(1);
    });

    it("DEF is always >= 0 regardless of artifacts", async () => {
      // Berserker Helm gives -2 DEF, stack 8 of them
      const artifacts = [4, 4, 4, 4, 4, 4, 4, 4];
      const stats = computeStats(artifacts);
      
      // Even with -16 DEF, should floor at 0
      expect(stats.def).to.be.gte(0);
    });
  });

  describe("Fuzz: Random artifact combinations", () => {
    const FUZZ_ITERATIONS = 20; // Adjust for thoroughness vs speed
    const rng = seededRandom(42); // Fixed seed for reproducibility

    for (let i = 0; i < FUZZ_ITERATIONS; i++) {
      const numArtifacts = Math.floor(rng() * 9); // 0-8 artifacts
      const artifacts = randomArtifacts(rng, numArtifacts);
      
      it(`fuzz #${i + 1}: ${numArtifacts} artifacts [${artifacts.join(",")}]`, async () => {
        // Compute expected stats using our helper
        const stats = computeStats(artifacts);
        
        // Verify invariants
        expect(stats.hp).to.be.gte(1);
        expect(stats.atk).to.be.gte(1);
        expect(stats.def).to.be.gte(0);

        // Generate random position
        const x = BigInt(Math.floor(rng() * 16));
        const y = BigInt(Math.floor(rng() * 16));
        const salt = BigInt(Math.floor(rng() * 1000000));
        const playerSalt = BigInt(Math.floor(rng() * 1000000));
        const gameId = BigInt(Math.floor(rng() * 100) + 1);

        // Compute commitments
        const commitment = await computePositionCommitment(x, y, salt);
        const statsCommitment = await computeStatsCommitment(
          BigInt(stats.hp),
          BigInt(stats.atk),
          BigInt(stats.def),
          playerSalt
        );

        // Pad artifacts to 8
        const paddedArtifacts = [...artifacts, ...Array(8).fill(0)].slice(0, 8);

        // Generate and verify proof
        const { proof, publicInputs } = await generateProof("combat_reveal", {
          x: x.toString(),
          y: y.toString(),
          salt: salt.toString(),
          player_salt: playerSalt.toString(),
          artifact_ids: paddedArtifacts.map(String),
          commitment,
          stats_commitment: statsCommitment,
          game_id: gameId.toString(),
        });

        const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
        expect(verified).to.be.true;
      });
    }
  });

  describe("Fuzz: Extreme stat combinations", () => {
    it("maximum possible HP", async () => {
      // Vitality Amulet (3): +20 HP
      // Soul Vessel (8): +15 HP
      // Phantom Cloak (5): +10 HP
      // Best HP combo: [3, 3, 3, 3, 8, 8, 5, 5]
      const artifacts = [3, 3, 3, 3, 8, 8, 5, 5];
      const stats = computeStats(artifacts);
      
      // HP = 100 + 4*20 + 2*15 + 2*10 = 100 + 80 + 30 + 20 = 230
      expect(stats.hp).to.equal(230);

      const { proof, publicInputs } = await proveWithArtifacts(artifacts);
      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("maximum possible ATK", async () => {
      // Berserker Helm (4): +8 ATK
      // Blood Crystal (7): +6 ATK
      const artifacts = [4, 4, 4, 4, 7, 7, 7, 7];
      const stats = computeStats(artifacts);
      
      // ATK = 10 + 4*8 + 4*6 = 10 + 32 + 24 = 66
      expect(stats.atk).to.equal(66);

      const { proof, publicInputs } = await proveWithArtifacts(artifacts);
      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });

    it("maximum possible DEF", async () => {
      // Phantom Cloak (5): +7 DEF
      // Iron Aegis (2): +5 DEF
      const artifacts = [5, 5, 5, 5, 2, 2, 2, 2];
      const stats = computeStats(artifacts);
      
      // DEF = 5 + 4*7 + 4*5 = 5 + 28 + 20 = 53
      expect(stats.def).to.equal(53);

      const { proof, publicInputs } = await proveWithArtifacts(artifacts);
      const verified = await verifyProofJS("combat_reveal", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });

  // Helper for quick artifact proofs
  async function proveWithArtifacts(artifacts: number[]) {
    const x = 5n;
    const y = 5n;
    const salt = 12345n;
    const playerSalt = 67890n;
    const gameId = 1n;

    const commitment = await computePositionCommitment(x, y, salt);
    const stats = computeStats(artifacts);
    const statsCommitment = await computeStatsCommitment(
      BigInt(stats.hp),
      BigInt(stats.atk),
      BigInt(stats.def),
      playerSalt
    );

    const paddedArtifacts = [...artifacts, ...Array(8).fill(0)].slice(0, 8);

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
});
