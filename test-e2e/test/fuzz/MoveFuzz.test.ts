import { expect } from "chai";
import {
  initBarretenberg,
  destroyBarretenberg,
  computePositionCommitment,
  generateProof,
  verifyProofJS,
  emptyWalls,
} from "../fixtures/GameFixture";

describe("Move Validation Fuzz Tests", function () {
  this.timeout(600000);

  before(async () => {
    await initBarretenberg();
  });

  after(async () => {
    await destroyBarretenberg();
  });

  // Seeded RNG for reproducibility
  function seededRandom(seed: number) {
    return function() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    };
  }

  describe("Invariant: All valid moves have Manhattan distance <= 1", () => {
    const DIRECTIONS = [
      { dx: 0, dy: 0, name: "stay" },
      { dx: 0, dy: -1, name: "north" },
      { dx: 0, dy: 1, name: "south" },
      { dx: 1, dy: 0, name: "east" },
      { dx: -1, dy: 0, name: "west" },
    ];

    // Test all valid moves from various positions
    const positions = [
      { x: 0, y: 0 },
      { x: 0, y: 15 },
      { x: 15, y: 0 },
      { x: 15, y: 15 },
      { x: 7, y: 7 },
      { x: 8, y: 8 },
    ];

    for (const pos of positions) {
      for (const dir of DIRECTIONS) {
        const newX = pos.x + dir.dx;
        const newY = pos.y + dir.dy;

        // Skip out of bounds
        if (newX < 0 || newX > 15 || newY < 0 || newY > 15) continue;

        it(`valid: (${pos.x},${pos.y}) → (${newX},${newY}) [${dir.name}]`, async () => {
          const oldCommitment = await computePositionCommitment(
            BigInt(pos.x), BigInt(pos.y), 111n
          );
          const newCommitment = await computePositionCommitment(
            BigInt(newX), BigInt(newY), 222n
          );

          const { proof, publicInputs } = await generateProof("valid_move", {
            old_x: pos.x.toString(),
            old_y: pos.y.toString(),
            old_salt: "111",
            new_x: newX.toString(),
            new_y: newY.toString(),
            new_salt: "222",
            old_commitment: oldCommitment,
            new_commitment: newCommitment,
            map_walls: emptyWalls(),
          });

          const verified = await verifyProofJS("valid_move", proof, publicInputs);
          expect(verified).to.be.true;
        });
      }
    }
  });

  describe("Invariant: No diagonal moves allowed", () => {
    const DIAGONALS = [
      { dx: 1, dy: 1 },
      { dx: 1, dy: -1 },
      { dx: -1, dy: 1 },
      { dx: -1, dy: -1 },
    ];

    for (const diag of DIAGONALS) {
      it(`rejects diagonal (5,5) → (${5 + diag.dx},${5 + diag.dy})`, async () => {
        const oldCommitment = await computePositionCommitment(5n, 5n, 111n);
        const newCommitment = await computePositionCommitment(
          BigInt(5 + diag.dx), BigInt(5 + diag.dy), 222n
        );

        try {
          await generateProof("valid_move", {
            old_x: "5",
            old_y: "5",
            old_salt: "111",
            new_x: (5 + diag.dx).toString(),
            new_y: (5 + diag.dy).toString(),
            new_salt: "222",
            old_commitment: oldCommitment,
            new_commitment: newCommitment,
            map_walls: emptyWalls(),
          });
          expect.fail("Should have thrown");
        } catch (e: any) {
          expect(e.message).to.include("not adjacent");
        }
      });
    }
  });

  describe("Fuzz: Random valid move sequences", () => {
    const rng = seededRandom(123);
    const NUM_SEQUENCES = 5;
    const MOVES_PER_SEQUENCE = 10;

    for (let seq = 0; seq < NUM_SEQUENCES; seq++) {
      it(`sequence #${seq + 1}: ${MOVES_PER_SEQUENCE} random valid moves`, async () => {
        let x = Math.floor(rng() * 16);
        let y = Math.floor(rng() * 16);
        let salt = BigInt(Math.floor(rng() * 1000000));

        for (let move = 0; move < MOVES_PER_SEQUENCE; move++) {
          // Pick a random valid direction
          const directions = [
            { dx: 0, dy: 0 },   // stay
            { dx: 0, dy: -1 },  // north
            { dx: 0, dy: 1 },   // south
            { dx: 1, dy: 0 },   // east
            { dx: -1, dy: 0 },  // west
          ];

          // Filter to valid moves (in bounds)
          const validDirs = directions.filter(d => {
            const nx = x + d.dx;
            const ny = y + d.dy;
            return nx >= 0 && nx <= 15 && ny >= 0 && ny <= 15;
          });

          const dir = validDirs[Math.floor(rng() * validDirs.length)];
          const newX = x + dir.dx;
          const newY = y + dir.dy;
          const newSalt = BigInt(Math.floor(rng() * 1000000));

          const oldCommitment = await computePositionCommitment(BigInt(x), BigInt(y), salt);
          const newCommitment = await computePositionCommitment(BigInt(newX), BigInt(newY), newSalt);

          const { proof, publicInputs } = await generateProof("valid_move", {
            old_x: x.toString(),
            old_y: y.toString(),
            old_salt: salt.toString(),
            new_x: newX.toString(),
            new_y: newY.toString(),
            new_salt: newSalt.toString(),
            old_commitment: oldCommitment,
            new_commitment: newCommitment,
            map_walls: emptyWalls(),
          });

          const verified = await verifyProofJS("valid_move", proof, publicInputs);
          expect(verified).to.be.true;

          // Update position for next move
          x = newX;
          y = newY;
          salt = newSalt;
        }
      });
    }
  });

  describe("Invariant: Walls always block moves", () => {
    it("wall at destination blocks move", async () => {
      // Wall at (6, 5): row 5, bit 6
      const walls = emptyWalls();
      walls[5] = "64"; // 0b01000000

      const oldCommitment = await computePositionCommitment(5n, 5n, 111n);
      const newCommitment = await computePositionCommitment(6n, 5n, 222n);

      try {
        await generateProof("valid_move", {
          old_x: "5",
          old_y: "5",
          old_salt: "111",
          new_x: "6",
          new_y: "5",
          new_salt: "222",
          old_commitment: oldCommitment,
          new_commitment: newCommitment,
          map_walls: walls,
        });
        expect.fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).to.include("wall");
      }
    });

    it("wall at origin still allows move away", async () => {
      // Wall at (5, 5) - but player was already there, moving to (6, 5)
      const walls = emptyWalls();
      walls[5] = "32"; // bit 5 = 0b00100000

      const oldCommitment = await computePositionCommitment(5n, 5n, 111n);
      const newCommitment = await computePositionCommitment(6n, 5n, 222n);

      // This should succeed (circuit only checks NEW position for walls)
      const { proof, publicInputs } = await generateProof("valid_move", {
        old_x: "5",
        old_y: "5",
        old_salt: "111",
        new_x: "6",
        new_y: "5",
        new_salt: "222",
        old_commitment: oldCommitment,
        new_commitment: newCommitment,
        map_walls: walls,
      });

      const verified = await verifyProofJS("valid_move", proof, publicInputs);
      expect(verified).to.be.true;
    });
  });
});
