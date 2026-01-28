// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.21;

uint256 constant VM_N = 32768;
uint256 constant VM_LOG_N = 15;
uint256 constant VM_NUMBER_OF_PUBLIC_INPUTS = 3;
library ValidMoveVerificationKey {
    function loadVerificationKey() internal pure returns (ValidMoveHonk.VerificationKey memory) {
        ValidMoveHonk.VerificationKey memory vk = ValidMoveHonk.VerificationKey({
            circuitSize: uint256(32768),
            logCircuitSize: uint256(15),
            publicInputsSize: uint256(3),
            ql: ValidMoveHonk.G1Point({ 
               x: uint256(0x0c3a38cc45974a3df0ea50b0d0370673d1a44a954da7b47369cd0424de0ba49b),
               y: uint256(0x27e028c207851cecf56195ddddc7d7a84d364bec82491c59d4aba83061d22816)
            }),
            qr: ValidMoveHonk.G1Point({ 
               x: uint256(0x0487822be904beba6f7c7c52dc7906bf52585acd7ee15da651c82e7b70576964),
               y: uint256(0x167ae3345d7c3388a31e0bd18404393e91db40ab54f63c5b41aa4b8351f8a80f)
            }),
            qo: ValidMoveHonk.G1Point({ 
               x: uint256(0x161ec9c1377b464b57e823773660a6daf57f0a8ec9a7754f58db697a42f94c7a),
               y: uint256(0x1ab6aac5f66cafa36b8d135fcb3ee8b25c3f4f73e50c928c56e0e31fc345e942)
            }),
            q4: ValidMoveHonk.G1Point({ 
               x: uint256(0x0dc1c55523a5e15877d73356838f111ec89f9b641100b5b49e3d3696ddb4a828),
               y: uint256(0x0f0f8f1c2941cd4f92ee7149e64a6adb492ab5cd3d40681cc082d1f4492301cf)
            }),
            qm: ValidMoveHonk.G1Point({ 
               x: uint256(0x1cae1784c732f91ecafb5f4ee7ec33d01f87b702387e7bfd231dd8f3f0c6cc80),
               y: uint256(0x158a79ae8b90c607d2d1fb95faed2ac2ee156445a403c1eed88c26f74da442d8)
            }),
            qc: ValidMoveHonk.G1Point({ 
               x: uint256(0x14087ccf7a221ddfd7660b2a767ce49f2e11e783eae9a054e6b7b708e52207ca),
               y: uint256(0x01833797307d840953a751532a6a0e4f6986d9b90fe9b81465a0ffdaad71667a)
            }),
            qArith: ValidMoveHonk.G1Point({ 
               x: uint256(0x0956b1b1e8c80881646cba74c4f3216ec6327cfeb203cc3a65f653108acf97f3),
               y: uint256(0x043ed698742d085abb43cc070146643efd4d321a038d7fb65e45e4fb4dd6af1e)
            }),
            qDeltaRange: ValidMoveHonk.G1Point({ 
               x: uint256(0x27e003c61d85aa963038dc499383a7b456ea9e6f220dd8f691e8b4d8df54c150),
               y: uint256(0x2d97564fc8eb53b60d49f747a1b147890a8f54b9547d174eee6eae714776dddb)
            }),
            qElliptic: ValidMoveHonk.G1Point({ 
               x: uint256(0x1b5b8c6f7ae32b5418ada2cdf0ac45daec6270fd1e3627774cc2b8c1e731a4b8),
               y: uint256(0x2b0403743723d9c2635a72f4ff211b11f3ac82b8da5d0ad4fe441e64b28bd0bb)
            }),
            qAux: ValidMoveHonk.G1Point({ 
               x: uint256(0x25ef18825c236d0f7dcd2c77e6ae94d49b748ed182dd25f6064d0ca5174119c7),
               y: uint256(0x244096485133f92e22431dc040822350ff7bc8b275d67644453301473af1d6e5)
            }),
            qLookup: ValidMoveHonk.G1Point({ 
               x: uint256(0x28479aeed9e3a22116e9f41d747609168b518c4141c7a2f204be074408475292),
               y: uint256(0x2c71c293c53d0b486b957dad30a3ef2a36868be26691c6cf76d15bc56770ac84)
            }),
            qPoseidon2External: ValidMoveHonk.G1Point({ 
               x: uint256(0x0911ed93fb20053fd81c7043f5ab1db3a2e00df4c2dc2b345960db3736d79369),
               y: uint256(0x26f58e664ccfd537ab0c5a9fb6fe28c393b2026a651cc733836a0ddffc7c3dcc)
            }),
            qPoseidon2Internal: ValidMoveHonk.G1Point({ 
               x: uint256(0x21e2307c5be8c528b51c06299d4de8979fce252dc35c13110c22413a0ee3f4f9),
               y: uint256(0x013a0ca664ed3994746f1fc0c1acf110811a9fd71fe4ee924a9e4464421993bd)
            }),
            s1: ValidMoveHonk.G1Point({ 
               x: uint256(0x2ba0ecae00a0a85d543e522f43345522d4e395161e21d614e6062c866b15a167),
               y: uint256(0x080fd05b8a56eb4af58d5250d8389a6b3fe687bf401561d2a8d12fe399d41fc6)
            }),
            s2: ValidMoveHonk.G1Point({ 
               x: uint256(0x2f43d8437a3f428680c17a0027f14dca590513b4e07d2618442f599148261d10),
               y: uint256(0x2edfea749d05472181c0d787d8c9364c1cd24ae756b86585dfc28c217fa1a1a4)
            }),
            s3: ValidMoveHonk.G1Point({ 
               x: uint256(0x03c67f01c2eb8af3c2476271289bd6915dfd7be0dd702929ed40b84f3f5264c2),
               y: uint256(0x17acfe4945254264cd10ea74481de1340c727ebb2bf08f7473022bd4a7bdc2ce)
            }),
            s4: ValidMoveHonk.G1Point({ 
               x: uint256(0x0f06d0d9a04b1c8ba5a589158f10572b9780d3ec0cf9562067314886eba4e2fb),
               y: uint256(0x02c4ae47311b7d19ece5b9a5a78a6d755e4303fdb4a408003ff80092a83727ff)
            }),
            t1: ValidMoveHonk.G1Point({ 
               x: uint256(0x24b8000045ca320266e83b61d1f9fe93604f9b09927d488db4fcd0334c170ae9),
               y: uint256(0x1587e22b6c7ebc2b5b4821bc53ee9549fe44d52bec17c19c725310efa82fe389)
            }),
            t2: ValidMoveHonk.G1Point({ 
               x: uint256(0x299699f952a4fe646d091638243ddaf0990da3f7133aa1ac983fa38623cb30f8),
               y: uint256(0x1be56eafa40421366463a96f2441b724f2dd1c8191c2037b9af5566a0828283a)
            }),
            t3: ValidMoveHonk.G1Point({ 
               x: uint256(0x2412bff32bd543e84a5f7551be8ce19c2cd560c3481de110e8d229cec6fe86ab),
               y: uint256(0x1233d8b435ca4124c21d2bee53a28344fd73aadc01d6d2dace501d72adba67b6)
            }),
            t4: ValidMoveHonk.G1Point({ 
               x: uint256(0x2ede7e5165c07a011fff71b1c732215583c6be192b63394012750337d3594f67),
               y: uint256(0x13361066e54a798d7d564d3b4dc9b415b2c43772f6dd0c473700262cc7f1bc65)
            }),
            id1: ValidMoveHonk.G1Point({ 
               x: uint256(0x1de9a29ec5d1b58f7af633542d0f3228cc5749b2f6036934ddd3ef0ef0797cca),
               y: uint256(0x0dc91bccdab481e171c3df0cf7f03078a63b2521e76a5b19082c122a2254334c)
            }),
            id2: ValidMoveHonk.G1Point({ 
               x: uint256(0x1bd0bffe8e11eddd1baadd84dc374e4d8a09fdb3da28f1d98951e09f40f877fe),
               y: uint256(0x0f94d07d482748cbc1c3ea6e758bd07e9f4fd1d7bbfad079f784266a89fc0b23)
            }),
            id3: ValidMoveHonk.G1Point({ 
               x: uint256(0x1b45e498fe971a2ff87b34dc1cf4cb22ea8ad521bb90fe363d105c7ae9e9fbc2),
               y: uint256(0x2a63f896c277cde558d99db70d90ac49d461968ffbae4240c8c8ef28e163ae97)
            }),
            id4: ValidMoveHonk.G1Point({ 
               x: uint256(0x2b18a326727ab6188b52154437e90345d48409aca224c53435c87452ee1ce951),
               y: uint256(0x15af07f0964912b846b81b8417946aaf4cce7aecc53ca5f6ec7b07017f719fb4)
            }),
            lagrangeFirst: ValidMoveHonk.G1Point({ 
               x: uint256(0x0000000000000000000000000000000000000000000000000000000000000001),
               y: uint256(0x0000000000000000000000000000000000000000000000000000000000000002)
            }),
            lagrangeLast: ValidMoveHonk.G1Point({ 
               x: uint256(0x271c25b4be6d708c5e3c1543b2b6ff1f9514aeea516f4ac1ac0c07f74a714d4a),
               y: uint256(0x1e9ea6b137ba7a0ab404ec38f949111a5291397e2041e438472eb0fb930d561e)
            })
        });
        return vk;
    }
}

pragma solidity ^0.8.27;

type Fr is uint256;

using { add as + } for Fr global;
using { sub as - } for Fr global;
using { mul as * } for Fr global;
using { exp as ^ } for Fr global;
using { notEqual as != } for Fr global;
using { equal as == } for Fr global;

uint256 constant MODULUS =
    21888242871839275222246405745257275088548364400416034343698204186575808495617; // Prime field order

Fr constant MINUS_ONE = Fr.wrap(MODULUS - 1);

// Instantiation
library ValidMoveFrLib
{
    function from(uint256 value) internal pure returns(Fr)
    {
        return Fr.wrap(value % MODULUS);
    }

    function fromBytes32(bytes32 value) internal pure returns(Fr)
    {
        return Fr.wrap(uint256(value) % MODULUS);
    }

    function toBytes32(Fr value) internal pure returns(bytes32)
    {
        return bytes32(Fr.unwrap(value));
    }

    function invert(Fr value) internal view returns(Fr)
    {
        uint256 v = Fr.unwrap(value);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly
        {
            let free := mload(0x40)
            mstore(free, 0x20)
            mstore(add(free, 0x20), 0x20)
            mstore(add(free, 0x40), 0x20)
            mstore(add(free, 0x60), v)
            mstore(add(free, 0x80), sub(MODULUS, 2))
            mstore(add(free, 0xa0), MODULUS)
            let success := staticcall(gas(), 0x05, free, 0xc0, 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0x00)
        }

        return Fr.wrap(result);
    }

    function pow(Fr base, uint256 v) internal view returns(Fr)
    {
        uint256 b = Fr.unwrap(base);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly
        {
            let free := mload(0x40)
            mstore(free, 0x20)
            mstore(add(free, 0x20), 0x20)
            mstore(add(free, 0x40), 0x20)
            mstore(add(free, 0x60), b)
            mstore(add(free, 0x80), v)
            mstore(add(free, 0xa0), MODULUS)
            let success := staticcall(gas(), 0x05, free, 0xc0, 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0x00)
        }

        return Fr.wrap(result);
    }

    function div(Fr numerator, Fr denominator) internal view returns(Fr)
    {
        return numerator * invert(denominator);
    }

    function sqr(Fr value) internal pure returns (Fr) {
        return value * value;
    }

    function unwrap(Fr value) internal pure returns (uint256) {
        return Fr.unwrap(value);
    }

    function neg(Fr value) internal pure returns (Fr) {
        return Fr.wrap(MODULUS - Fr.unwrap(value));
    }
}

// Free functions
function add(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(addmod(Fr.unwrap(a), Fr.unwrap(b), MODULUS));
}

function mul(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(mulmod(Fr.unwrap(a), Fr.unwrap(b), MODULUS));
}

function sub(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(addmod(Fr.unwrap(a), MODULUS - Fr.unwrap(b), MODULUS));
}

function exp(Fr base, Fr exponent) pure returns(Fr)
{
    if (Fr.unwrap(exponent) == 0) return Fr.wrap(1);

    for (uint256 i = 1; i < Fr.unwrap(exponent); i += i) {
        base = base * base;
    }
    return base;
}

function notEqual(Fr a, Fr b) pure returns(bool)
{
    return Fr.unwrap(a) != Fr.unwrap(b);
}

function equal(Fr a, Fr b) pure returns(bool)
{
    return Fr.unwrap(a) == Fr.unwrap(b);
}

uint256 constant CONST_PROOF_SIZE_LOG_N = 28;

uint256 constant NUMBER_OF_SUBRELATIONS = 26;
uint256 constant BATCHED_RELATION_PARTIAL_LENGTH = 8;
uint256 constant NUMBER_OF_ENTITIES = 40;
uint256 constant NUMBER_UNSHIFTED = 35;
uint256 constant NUMBER_TO_BE_SHIFTED = 5;

// Alphas are used as relation separators so there should be NUMBER_OF_SUBRELATIONS - 1
uint256 constant NUMBER_OF_ALPHAS = 25;

// Prime field order
uint256 constant Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583; // EC group order. F_q
uint256 constant P = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // Prime field order, F_r

// ENUM FOR WIRES
enum WIRE {
    Q_M,
    Q_C,
    Q_L,
    Q_R,
    Q_O,
    Q_4,
    Q_LOOKUP,
    Q_ARITH,
    Q_RANGE,
    Q_ELLIPTIC,
    Q_AUX,
    Q_POSEIDON2_EXTERNAL,
    Q_POSEIDON2_INTERNAL,
    SIGMA_1,
    SIGMA_2,
    SIGMA_3,
    SIGMA_4,
    ID_1,
    ID_2,
    ID_3,
    ID_4,
    TABLE_1,
    TABLE_2,
    TABLE_3,
    TABLE_4,
    LAGRANGE_FIRST,
    LAGRANGE_LAST,
    W_L,
    W_R,
    W_O,
    W_4,
    Z_PERM,
    LOOKUP_INVERSES,
    LOOKUP_READ_COUNTS,
    LOOKUP_READ_TAGS,
    W_L_SHIFT,
    W_R_SHIFT,
    W_O_SHIFT,
    W_4_SHIFT,
    Z_PERM_SHIFT
}

library ValidMoveHonk {
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    struct G1ProofPoint {
        uint256 x_0;
        uint256 x_1;
        uint256 y_0;
        uint256 y_1;
    }

    struct VerificationKey {
        // Misc Params
        uint256 circuitSize;
        uint256 logCircuitSize;
        uint256 publicInputsSize;
        // Selectors
        G1Point qm;
        G1Point qc;
        G1Point ql;
        G1Point qr;
        G1Point qo;
        G1Point q4;
        G1Point qLookup; // Lookup
        G1Point qArith; // Arithmetic widget
        G1Point qDeltaRange; // Delta Range sort
        G1Point qAux; // Auxillary
        G1Point qElliptic; // Auxillary
        G1Point qPoseidon2External;
        G1Point qPoseidon2Internal;
        // Copy cnstraints
        G1Point s1;
        G1Point s2;
        G1Point s3;
        G1Point s4;
        // Copy identity
        G1Point id1;
        G1Point id2;
        G1Point id3;
        G1Point id4;
        // Precomputed lookup table
        G1Point t1;
        G1Point t2;
        G1Point t3;
        G1Point t4;
        // Fixed first and last
        G1Point lagrangeFirst;
        G1Point lagrangeLast;
    }

    struct RelationParameters {
        // challenges
        Fr eta;
        Fr etaTwo;
        Fr etaThree;
        Fr beta;
        Fr gamma;
        // derived
        Fr publicInputsDelta;
    }


    struct Proof {
        // Free wires
        ValidMoveHonk.G1ProofPoint w1;
        ValidMoveHonk.G1ProofPoint w2;
        ValidMoveHonk.G1ProofPoint w3;
        ValidMoveHonk.G1ProofPoint w4;
        // Lookup helpers - Permutations
        ValidMoveHonk.G1ProofPoint zPerm;
        // Lookup helpers - logup
        ValidMoveHonk.G1ProofPoint lookupReadCounts;
        ValidMoveHonk.G1ProofPoint lookupReadTags;
        ValidMoveHonk.G1ProofPoint lookupInverses;
        // Sumcheck
        Fr[BATCHED_RELATION_PARTIAL_LENGTH][CONST_PROOF_SIZE_LOG_N] sumcheckUnivariates;
        Fr[NUMBER_OF_ENTITIES] sumcheckEvaluations;
        // Shplemini
        ValidMoveHonk.G1ProofPoint[CONST_PROOF_SIZE_LOG_N - 1] geminiFoldComms;
        Fr[CONST_PROOF_SIZE_LOG_N] geminiAEvaluations;
        ValidMoveHonk.G1ProofPoint shplonkQ;
        ValidMoveHonk.G1ProofPoint kzgQuotient;
    }
}

// Transcript library to generate fiat shamir challenges
struct Transcript {
    // Oink
    ValidMoveHonk.RelationParameters relationParameters;
    Fr[NUMBER_OF_ALPHAS] alphas;
    Fr[CONST_PROOF_SIZE_LOG_N] gateChallenges;
    // Sumcheck
    Fr[CONST_PROOF_SIZE_LOG_N] sumCheckUChallenges;
    // Gemini
    Fr rho;
    Fr geminiR;
    // Shplonk
    Fr shplonkNu;
    Fr shplonkZ;
}

library ValidMoveTranscriptLib {
    function generateTranscript(ValidMoveHonk.Proof memory proof, bytes32[] calldata publicInputs, uint256 circuitSize, uint256 publicInputsSize, uint256 pubInputsOffset)
        internal
        pure
        returns (Transcript memory t)
    {
        Fr previousChallenge;
        (t.relationParameters, previousChallenge) =
            generateRelationParametersChallenges(proof, publicInputs, circuitSize, publicInputsSize, pubInputsOffset, previousChallenge);

        (t.alphas, previousChallenge) = generateAlphaChallenges(previousChallenge, proof);

        (t.gateChallenges, previousChallenge) = generateGateChallenges(previousChallenge);

        (t.sumCheckUChallenges, previousChallenge) = generateSumcheckChallenges(proof, previousChallenge);

        (t.rho, previousChallenge) = generateRhoChallenge(proof, previousChallenge);

        (t.geminiR, previousChallenge) = generateGeminiRChallenge(proof, previousChallenge);

        (t.shplonkNu, previousChallenge) = generateShplonkNuChallenge(proof, previousChallenge);

        (t.shplonkZ, previousChallenge) = generateShplonkZChallenge(proof, previousChallenge);

        return t;
    }

    function splitChallenge(Fr challenge) internal pure returns (Fr first, Fr second) {
        uint256 challengeU256 = uint256(Fr.unwrap(challenge));
        uint256 lo = challengeU256 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 hi = challengeU256 >> 128;
        first = ValidMoveFrLib.fromBytes32(bytes32(lo));
        second = ValidMoveFrLib.fromBytes32(bytes32(hi));
    }

    function generateRelationParametersChallenges(
        ValidMoveHonk.Proof memory proof,
        bytes32[] calldata publicInputs,
        uint256 circuitSize,
        uint256 publicInputsSize,
        uint256 pubInputsOffset,
        Fr previousChallenge
    ) internal pure returns (ValidMoveHonk.RelationParameters memory rp, Fr nextPreviousChallenge) {
        (rp.eta, rp.etaTwo, rp.etaThree, previousChallenge) =
            generateEtaChallenge(proof, publicInputs, circuitSize, publicInputsSize, pubInputsOffset);

        (rp.beta, rp.gamma, nextPreviousChallenge) = generateBetaAndGammaChallenges(previousChallenge, proof);

    }

    function generateEtaChallenge(ValidMoveHonk.Proof memory proof, bytes32[] calldata publicInputs, uint256 circuitSize, uint256 publicInputsSize, uint256 pubInputsOffset)
        internal
        pure
        returns (Fr eta, Fr etaTwo, Fr etaThree, Fr previousChallenge)
    {
        bytes32[] memory round0 = new bytes32[](3 + publicInputsSize + 12);
        round0[0] = bytes32(circuitSize);
        round0[1] = bytes32(publicInputsSize);
        round0[2] = bytes32(pubInputsOffset);
        for (uint256 i = 0; i < publicInputsSize; i++) {
            round0[3 + i] = bytes32(publicInputs[i]);
        }

        // Create the first challenge
        // Note: w4 is added to the challenge later on
        round0[3 + publicInputsSize] = bytes32(proof.w1.x_0);
        round0[3 + publicInputsSize + 1] = bytes32(proof.w1.x_1);
        round0[3 + publicInputsSize + 2] = bytes32(proof.w1.y_0);
        round0[3 + publicInputsSize + 3] = bytes32(proof.w1.y_1);
        round0[3 + publicInputsSize + 4] = bytes32(proof.w2.x_0);
        round0[3 + publicInputsSize + 5] = bytes32(proof.w2.x_1);
        round0[3 + publicInputsSize + 6] = bytes32(proof.w2.y_0);
        round0[3 + publicInputsSize + 7] = bytes32(proof.w2.y_1);
        round0[3 + publicInputsSize + 8] = bytes32(proof.w3.x_0);
        round0[3 + publicInputsSize + 9] = bytes32(proof.w3.x_1);
        round0[3 + publicInputsSize + 10] = bytes32(proof.w3.y_0);
        round0[3 + publicInputsSize + 11] = bytes32(proof.w3.y_1);

        previousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(round0)));
        (eta, etaTwo) = splitChallenge(previousChallenge);
        previousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(previousChallenge))));
        Fr unused;
        (etaThree, unused) = splitChallenge(previousChallenge);
    }

    function generateBetaAndGammaChallenges(Fr previousChallenge, ValidMoveHonk.Proof memory proof)
        internal
        pure
        returns (Fr beta, Fr gamma, Fr nextPreviousChallenge)
    {
        bytes32[13] memory round1;
        round1[0] = ValidMoveFrLib.toBytes32(previousChallenge);
        round1[1] = bytes32(proof.lookupReadCounts.x_0);
        round1[2] = bytes32(proof.lookupReadCounts.x_1);
        round1[3] = bytes32(proof.lookupReadCounts.y_0);
        round1[4] = bytes32(proof.lookupReadCounts.y_1);
        round1[5] = bytes32(proof.lookupReadTags.x_0);
        round1[6] = bytes32(proof.lookupReadTags.x_1);
        round1[7] = bytes32(proof.lookupReadTags.y_0);
        round1[8] = bytes32(proof.lookupReadTags.y_1);
        round1[9] = bytes32(proof.w4.x_0);
        round1[10] = bytes32(proof.w4.x_1);
        round1[11] = bytes32(proof.w4.y_0);
        round1[12] = bytes32(proof.w4.y_1);

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(round1)));
        (beta, gamma) = splitChallenge(nextPreviousChallenge);
    }

    // Alpha challenges non-linearise the gate contributions
    function generateAlphaChallenges(Fr previousChallenge, ValidMoveHonk.Proof memory proof)
        internal
        pure
        returns (Fr[NUMBER_OF_ALPHAS] memory alphas, Fr nextPreviousChallenge)
    {
        // Generate the original sumcheck alpha 0 by hashing zPerm and zLookup
        uint256[9] memory alpha0;
        alpha0[0] = Fr.unwrap(previousChallenge);
        alpha0[1] = proof.lookupInverses.x_0;
        alpha0[2] = proof.lookupInverses.x_1;
        alpha0[3] = proof.lookupInverses.y_0;
        alpha0[4] = proof.lookupInverses.y_1;
        alpha0[5] = proof.zPerm.x_0;
        alpha0[6] = proof.zPerm.x_1;
        alpha0[7] = proof.zPerm.y_0;
        alpha0[8] = proof.zPerm.y_1;

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(alpha0)));
        (alphas[0], alphas[1]) = splitChallenge(nextPreviousChallenge);

        for (uint256 i = 1; i < NUMBER_OF_ALPHAS / 2; i++) {
            nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(nextPreviousChallenge))));
            (alphas[2 * i], alphas[2 * i + 1]) = splitChallenge(nextPreviousChallenge);
        }
        if (((NUMBER_OF_ALPHAS & 1) == 1) && (NUMBER_OF_ALPHAS > 2)) {
            nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(nextPreviousChallenge))));
            Fr unused;
            (alphas[NUMBER_OF_ALPHAS - 1], unused) = splitChallenge(nextPreviousChallenge);
        }
    }

    function generateGateChallenges(Fr previousChallenge)
        internal
        pure
        returns (Fr[CONST_PROOF_SIZE_LOG_N] memory gateChallenges, Fr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            previousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(previousChallenge))));
            Fr unused;
            (gateChallenges[i], unused) = splitChallenge(previousChallenge);
        }
        nextPreviousChallenge = previousChallenge;
    }

    function generateSumcheckChallenges(ValidMoveHonk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr[CONST_PROOF_SIZE_LOG_N] memory sumcheckChallenges, Fr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            Fr[BATCHED_RELATION_PARTIAL_LENGTH + 1] memory univariateChal;
            univariateChal[0] = prevChallenge;

            for (uint256 j = 0; j < BATCHED_RELATION_PARTIAL_LENGTH; j++) {
                univariateChal[j + 1] = proof.sumcheckUnivariates[i][j];
            }
            prevChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(univariateChal)));
            Fr unused;
            (sumcheckChallenges[i], unused) = splitChallenge(prevChallenge);
        }
        nextPreviousChallenge = prevChallenge;
    }

    function generateRhoChallenge(ValidMoveHonk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr rho, Fr nextPreviousChallenge)
    {
        Fr[NUMBER_OF_ENTITIES + 1] memory rhoChallengeElements;
        rhoChallengeElements[0] = prevChallenge;

        for (uint256 i = 0; i < NUMBER_OF_ENTITIES; i++) {
            rhoChallengeElements[i + 1] = proof.sumcheckEvaluations[i];
        }

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(rhoChallengeElements)));
        Fr unused;
        (rho, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateGeminiRChallenge(ValidMoveHonk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr geminiR, Fr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N - 1) * 4 + 1] memory gR;
        gR[0] = Fr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; i++) {
            gR[1 + i * 4] = proof.geminiFoldComms[i].x_0;
            gR[2 + i * 4] = proof.geminiFoldComms[i].x_1;
            gR[3 + i * 4] = proof.geminiFoldComms[i].y_0;
            gR[4 + i * 4] = proof.geminiFoldComms[i].y_1;
        }

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(gR)));
        Fr unused;
        (geminiR, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkNuChallenge(ValidMoveHonk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr shplonkNu, Fr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N) + 1] memory shplonkNuChallengeElements;
        shplonkNuChallengeElements[0] = Fr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            shplonkNuChallengeElements[i + 1] = Fr.unwrap(proof.geminiAEvaluations[i]);
        }

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(shplonkNuChallengeElements)));
        Fr unused;
        (shplonkNu, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkZChallenge(ValidMoveHonk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr shplonkZ, Fr nextPreviousChallenge)
    {
        uint256[5] memory shplonkZChallengeElements;
        shplonkZChallengeElements[0] = Fr.unwrap(prevChallenge);

        shplonkZChallengeElements[1] = proof.shplonkQ.x_0;
        shplonkZChallengeElements[2] = proof.shplonkQ.x_1;
        shplonkZChallengeElements[3] = proof.shplonkQ.y_0;
        shplonkZChallengeElements[4] = proof.shplonkQ.y_1;

        nextPreviousChallenge = ValidMoveFrLib.fromBytes32(keccak256(abi.encodePacked(shplonkZChallengeElements)));
        Fr unused;
        (shplonkZ, unused) = splitChallenge(nextPreviousChallenge);
    }

    function loadProof(bytes calldata proof) internal pure returns (ValidMoveHonk.Proof memory p) {
        // Commitments
        p.w1 = bytesToG1ProofPoint(proof[0x0:0x80]);

        p.w2 = bytesToG1ProofPoint(proof[0x80:0x100]);
        p.w3 = bytesToG1ProofPoint(proof[0x100:0x180]);

        // Lookup / Permutation Helper Commitments
        p.lookupReadCounts = bytesToG1ProofPoint(proof[0x180:0x200]);
        p.lookupReadTags = bytesToG1ProofPoint(proof[0x200:0x280]);
        p.w4 = bytesToG1ProofPoint(proof[0x280:0x300]);
        p.lookupInverses = bytesToG1ProofPoint(proof[0x300:0x380]);
        p.zPerm = bytesToG1ProofPoint(proof[0x380:0x400]);
        uint256 boundary = 0x400;

        // Sumcheck univariates
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            for (uint256 j = 0; j < BATCHED_RELATION_PARTIAL_LENGTH; j++) {
                p.sumcheckUnivariates[i][j] = bytesToFr(proof[boundary:boundary + 0x20]);
                boundary += 0x20;
            }
        }
        // Sumcheck evaluations
        for (uint256 i = 0; i < NUMBER_OF_ENTITIES; i++) {
            p.sumcheckEvaluations[i] = bytesToFr(proof[boundary:boundary + 0x20]);
            boundary += 0x20;
        }

        // Gemini
        // Read gemini fold univariates
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; i++) {
            p.geminiFoldComms[i] = bytesToG1ProofPoint(proof[boundary:boundary + 0x80]);
            boundary += 0x80;
        }

        // Read gemini a evaluations
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            p.geminiAEvaluations[i] = bytesToFr(proof[boundary:boundary + 0x20]);
            boundary += 0x20;
        }

        // Shplonk
        p.shplonkQ = bytesToG1ProofPoint(proof[boundary:boundary + 0x80]);
        boundary = boundary + 0x80;
        // KZG
        p.kzgQuotient = bytesToG1ProofPoint(proof[boundary:boundary + 0x80]);
    }
}


// Fr utility

function bytesToFr(bytes calldata proofSection) pure returns (Fr scalar) {
    require(proofSection.length == 0x20, "invalid bytes scalar");
    scalar = ValidMoveFrLib.fromBytes32(bytes32(proofSection));
}

// EC Point utilities
function convertProofPoint(ValidMoveHonk.G1ProofPoint memory input) pure returns (ValidMoveHonk.G1Point memory) {
    return ValidMoveHonk.G1Point({x: input.x_0 | (input.x_1 << 136), y: input.y_0 | (input.y_1 << 136)});
}

function bytesToG1ProofPoint(bytes calldata proofSection) pure returns (ValidMoveHonk.G1ProofPoint memory point) {
    require(proofSection.length == 0x80, "invalid bytes point");
    point = ValidMoveHonk.G1ProofPoint({
        x_0: uint256(bytes32(proofSection[0x00:0x20])),
        x_1: uint256(bytes32(proofSection[0x20:0x40])),
        y_0: uint256(bytes32(proofSection[0x40:0x60])),
        y_1: uint256(bytes32(proofSection[0x60:0x80]))
    });
}

function negateInplace(ValidMoveHonk.G1Point memory point) pure returns (ValidMoveHonk.G1Point memory) {
    point.y = (Q - point.y) % Q;
    return point;
}

 function pairing(ValidMoveHonk.G1Point memory rhs, ValidMoveHonk.G1Point memory lhs) view returns (bool) {
        bytes memory input = abi.encodePacked(
            rhs.x,
            rhs.y,
            // Fixed G1 point
            uint256(0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2),
            uint256(0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed),
            uint256(0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b),
            uint256(0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa),
            lhs.x,
            lhs.y,
            // G1 point from VK
            uint256(0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1),
            uint256(0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0),
            uint256(0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4),
            uint256(0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55)
        );

        (bool success, bytes memory result) = address(0x08).staticcall(input);
        bool decodedResult = abi.decode(result, (bool));
        return success && decodedResult;
    }


library ValidMoveRelationsLib {
    Fr internal constant GRUMPKIN_CURVE_B_PARAMETER_NEGATED = Fr.wrap(17); // -(-17)

    function accumulateRelationEvaluations(
         Fr[NUMBER_OF_ENTITIES] memory purportedEvaluations,
        ValidMoveHonk.RelationParameters memory rp,
        Fr[NUMBER_OF_ALPHAS] memory alphas,
        Fr powPartialEval
    ) internal pure returns (Fr accumulator) {
        Fr[NUMBER_OF_SUBRELATIONS] memory evaluations;

        // Accumulate all relations in Ultra Honk - each with varying number of subrelations
        accumulateArithmeticRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulatePermutationRelation(purportedEvaluations, rp, evaluations, powPartialEval);
        accumulateLogDerivativeLookupRelation(purportedEvaluations, rp, evaluations, powPartialEval);
        accumulateDeltaRangeRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulateEllipticRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulateAuxillaryRelation(purportedEvaluations, rp, evaluations, powPartialEval);
        accumulatePoseidonExternalRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulatePoseidonInternalRelation(purportedEvaluations, evaluations, powPartialEval);
        // batch the subrelations with the alpha challenges to obtain the full honk relation
        accumulator = scaleAndBatchSubrelations(evaluations, alphas);
    }

    /**
     * Aesthetic helper function that is used to index by enum into proof.sumcheckEvaluations, it avoids
     * the relation checking code being cluttered with uint256 type casting, which is often a different colour in code
     * editors, and thus is noisy.
     */
    function wire(Fr[NUMBER_OF_ENTITIES] memory p, WIRE _wire) internal pure returns (Fr) {
        return p[uint256(_wire)];
    }

    uint256 internal constant NEG_HALF_MODULO_P = 0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000000;
    /**
     * Ultra Arithmetic Relation
     *
     */
    function accumulateArithmeticRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        // Relation 0
        Fr q_arith = wire(p, WIRE.Q_ARITH);
        {
            Fr neg_half = Fr.wrap(NEG_HALF_MODULO_P);

            Fr accum = (q_arith - Fr.wrap(3)) * (wire(p, WIRE.Q_M) * wire(p, WIRE.W_R) * wire(p, WIRE.W_L)) * neg_half;
            accum = accum + (wire(p, WIRE.Q_L) * wire(p, WIRE.W_L)) + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_R))
                + (wire(p, WIRE.Q_O) * wire(p, WIRE.W_O)) + (wire(p, WIRE.Q_4) * wire(p, WIRE.W_4)) + wire(p, WIRE.Q_C);
            accum = accum + (q_arith - Fr.wrap(1)) * wire(p, WIRE.W_4_SHIFT);
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[0] = accum;
        }

        // Relation 1
        {
            Fr accum = wire(p, WIRE.W_L) + wire(p, WIRE.W_4) - wire(p, WIRE.W_L_SHIFT) + wire(p, WIRE.Q_M);
            accum = accum * (q_arith - Fr.wrap(2));
            accum = accum * (q_arith - Fr.wrap(1));
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[1] = accum;
        }
    }

    function accumulatePermutationRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        ValidMoveHonk.RelationParameters memory rp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr grand_product_numerator;
        Fr grand_product_denominator;

        {
            Fr num = wire(p, WIRE.W_L) + wire(p, WIRE.ID_1) * rp.beta + rp.gamma;
            num = num * (wire(p, WIRE.W_R) + wire(p, WIRE.ID_2) * rp.beta + rp.gamma);
            num = num * (wire(p, WIRE.W_O) + wire(p, WIRE.ID_3) * rp.beta + rp.gamma);
            num = num * (wire(p, WIRE.W_4) + wire(p, WIRE.ID_4) * rp.beta + rp.gamma);

            grand_product_numerator = num;
        }
        {
            Fr den = wire(p, WIRE.W_L) + wire(p, WIRE.SIGMA_1) * rp.beta + rp.gamma;
            den = den * (wire(p, WIRE.W_R) + wire(p, WIRE.SIGMA_2) * rp.beta + rp.gamma);
            den = den * (wire(p, WIRE.W_O) + wire(p, WIRE.SIGMA_3) * rp.beta + rp.gamma);
            den = den * (wire(p, WIRE.W_4) + wire(p, WIRE.SIGMA_4) * rp.beta + rp.gamma);

            grand_product_denominator = den;
        }

        // Contribution 2
        {
            Fr acc = (wire(p, WIRE.Z_PERM) + wire(p, WIRE.LAGRANGE_FIRST)) * grand_product_numerator;

            acc = acc
                - (
                    (wire(p, WIRE.Z_PERM_SHIFT) + (wire(p, WIRE.LAGRANGE_LAST) * rp.publicInputsDelta))
                        * grand_product_denominator
                );
            acc = acc * domainSep;
            evals[2] = acc;
        }

        // Contribution 3
        {
            Fr acc = (wire(p, WIRE.LAGRANGE_LAST) * wire(p, WIRE.Z_PERM_SHIFT)) * domainSep;
            evals[3] = acc;
        }
    }

    function accumulateLogDerivativeLookupRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        ValidMoveHonk.RelationParameters memory rp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr write_term;
        Fr read_term;

        // Calculate the write term (the table accumulation)
        {
            write_term = wire(p, WIRE.TABLE_1) + rp.gamma + (wire(p, WIRE.TABLE_2) * rp.eta)
                + (wire(p, WIRE.TABLE_3) * rp.etaTwo) + (wire(p, WIRE.TABLE_4) * rp.etaThree);
        }

        // Calculate the write term
        {
            Fr derived_entry_1 = wire(p, WIRE.W_L) + rp.gamma + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_L_SHIFT));
            Fr derived_entry_2 = wire(p, WIRE.W_R) + wire(p, WIRE.Q_M) * wire(p, WIRE.W_R_SHIFT);
            Fr derived_entry_3 = wire(p, WIRE.W_O) + wire(p, WIRE.Q_C) * wire(p, WIRE.W_O_SHIFT);

            read_term = derived_entry_1 + (derived_entry_2 * rp.eta) + (derived_entry_3 * rp.etaTwo)
                + (wire(p, WIRE.Q_O) * rp.etaThree);
        }

        Fr read_inverse = wire(p, WIRE.LOOKUP_INVERSES) * write_term;
        Fr write_inverse = wire(p, WIRE.LOOKUP_INVERSES) * read_term;

        Fr inverse_exists_xor = wire(p, WIRE.LOOKUP_READ_TAGS) + wire(p, WIRE.Q_LOOKUP)
            - (wire(p, WIRE.LOOKUP_READ_TAGS) * wire(p, WIRE.Q_LOOKUP));

        // Inverse calculated correctly relation
        Fr accumulatorNone = read_term * write_term * wire(p, WIRE.LOOKUP_INVERSES) - inverse_exists_xor;
        accumulatorNone = accumulatorNone * domainSep;

        // Inverse
        Fr accumulatorOne = wire(p, WIRE.Q_LOOKUP) * read_inverse - wire(p, WIRE.LOOKUP_READ_COUNTS) * write_inverse;

        evals[4] = accumulatorNone;
        evals[5] = accumulatorOne;
    }

    function accumulateDeltaRangeRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr minus_one = Fr.wrap(0) - Fr.wrap(1);
        Fr minus_two = Fr.wrap(0) - Fr.wrap(2);
        Fr minus_three = Fr.wrap(0) - Fr.wrap(3);

        // Compute wire differences
        Fr delta_1 = wire(p, WIRE.W_R) - wire(p, WIRE.W_L);
        Fr delta_2 = wire(p, WIRE.W_O) - wire(p, WIRE.W_R);
        Fr delta_3 = wire(p, WIRE.W_4) - wire(p, WIRE.W_O);
        Fr delta_4 = wire(p, WIRE.W_L_SHIFT) - wire(p, WIRE.W_4);

        // Contribution 6
        {
            Fr acc = delta_1;
            acc = acc * (delta_1 + minus_one);
            acc = acc * (delta_1 + minus_two);
            acc = acc * (delta_1 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[6] = acc;
        }

        // Contribution 7
        {
            Fr acc = delta_2;
            acc = acc * (delta_2 + minus_one);
            acc = acc * (delta_2 + minus_two);
            acc = acc * (delta_2 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[7] = acc;
        }

        // Contribution 8
        {
            Fr acc = delta_3;
            acc = acc * (delta_3 + minus_one);
            acc = acc * (delta_3 + minus_two);
            acc = acc * (delta_3 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[8] = acc;
        }

        // Contribution 9
        {
            Fr acc = delta_4;
            acc = acc * (delta_4 + minus_one);
            acc = acc * (delta_4 + minus_two);
            acc = acc * (delta_4 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[9] = acc;
        }
    }

    struct EllipticParams {
        // Points
        Fr x_1;
        Fr y_1;
        Fr x_2;
        Fr y_2;
        Fr y_3;
        Fr x_3;
        // push accumulators into memory
        Fr x_double_identity;
    }

    function accumulateEllipticRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        EllipticParams memory ep;
        ep.x_1 = wire(p, WIRE.W_R);
        ep.y_1 = wire(p, WIRE.W_O);

        ep.x_2 = wire(p, WIRE.W_L_SHIFT);
        ep.y_2 = wire(p, WIRE.W_4_SHIFT);
        ep.y_3 = wire(p, WIRE.W_O_SHIFT);
        ep.x_3 = wire(p, WIRE.W_R_SHIFT);

        Fr q_sign = wire(p, WIRE.Q_L);
        Fr q_is_double = wire(p, WIRE.Q_M);

        // Contribution 10 point addition, x-coordinate check
        // q_elliptic * (x3 + x2 + x1)(x2 - x1)(x2 - x1) - y2^2 - y1^2 + 2(y2y1)*q_sign = 0
        Fr x_diff = (ep.x_2 - ep.x_1);
        Fr y1_sqr = (ep.y_1 * ep.y_1);
        {
            // Move to top
            Fr partialEval = domainSep;

            Fr y2_sqr = (ep.y_2 * ep.y_2);
            Fr y1y2 = ep.y_1 * ep.y_2 * q_sign;
            Fr x_add_identity = (ep.x_3 + ep.x_2 + ep.x_1);
            x_add_identity = x_add_identity * x_diff * x_diff;
            x_add_identity = x_add_identity - y2_sqr - y1_sqr + y1y2 + y1y2;

            evals[10] = x_add_identity * partialEval * wire(p, WIRE.Q_ELLIPTIC) * (Fr.wrap(1) - q_is_double);
        }

        // Contribution 11 point addition, x-coordinate check
        // q_elliptic * (q_sign * y1 + y3)(x2 - x1) + (x3 - x1)(y2 - q_sign * y1) = 0
        {
            Fr y1_plus_y3 = ep.y_1 + ep.y_3;
            Fr y_diff = ep.y_2 * q_sign - ep.y_1;
            Fr y_add_identity = y1_plus_y3 * x_diff + (ep.x_3 - ep.x_1) * y_diff;
            evals[11] = y_add_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * (Fr.wrap(1) - q_is_double);
        }

        // Contribution 10 point doubling, x-coordinate check
        // (x3 + x1 + x1) (4y1*y1) - 9 * x1 * x1 * x1 * x1 = 0
        // N.B. we're using the equivalence x1*x1*x1 === y1*y1 - curve_b to reduce degree by 1
        {
            Fr x_pow_4 = (y1_sqr + GRUMPKIN_CURVE_B_PARAMETER_NEGATED) * ep.x_1;
            Fr y1_sqr_mul_4 = y1_sqr + y1_sqr;
            y1_sqr_mul_4 = y1_sqr_mul_4 + y1_sqr_mul_4;
            Fr x1_pow_4_mul_9 = x_pow_4 * Fr.wrap(9);

            // NOTE: pushed into memory (stack >:'( )
            ep.x_double_identity = (ep.x_3 + ep.x_1 + ep.x_1) * y1_sqr_mul_4 - x1_pow_4_mul_9;

            Fr acc = ep.x_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
            evals[10] = evals[10] + acc;
        }

        // Contribution 11 point doubling, y-coordinate check
        // (y1 + y1) (2y1) - (3 * x1 * x1)(x1 - x3) = 0
        {
            Fr x1_sqr_mul_3 = (ep.x_1 + ep.x_1 + ep.x_1) * ep.x_1;
            Fr y_double_identity = x1_sqr_mul_3 * (ep.x_1 - ep.x_3) - (ep.y_1 + ep.y_1) * (ep.y_1 + ep.y_3);
            evals[11] = evals[11] + y_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
        }
    }

    // Constants for the auxiliary relation
    Fr constant LIMB_SIZE = Fr.wrap(uint256(1) << 68);
    Fr constant SUBLIMB_SHIFT = Fr.wrap(uint256(1) << 14);

    // Parameters used within the Auxiliary Relation
    // A struct is used to work around stack too deep. This relation has alot of variables
    struct AuxParams {
        Fr limb_subproduct;
        Fr non_native_field_gate_1;
        Fr non_native_field_gate_2;
        Fr non_native_field_gate_3;
        Fr limb_accumulator_1;
        Fr limb_accumulator_2;
        Fr memory_record_check;
        Fr partial_record_check;
        Fr next_gate_access_type;
        Fr record_delta;
        Fr index_delta;
        Fr adjacent_values_match_if_adjacent_indices_match;
        Fr adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation;
        Fr access_check;
        Fr next_gate_access_type_is_boolean;
        Fr ROM_consistency_check_identity;
        Fr RAM_consistency_check_identity;
        Fr timestamp_delta;
        Fr RAM_timestamp_check_identity;
        Fr memory_identity;
        Fr index_is_monotonically_increasing;
        Fr auxiliary_identity;
    }

    function accumulateAuxillaryRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        ValidMoveHonk.RelationParameters memory rp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        AuxParams memory ap;

        /**
         * Contribution 12
         * Non native field arithmetic gate 2
         * deg 4
         *
         *             _                                                                               _
         *            /   _                   _                               _       14                \
         * q_2 . q_4 |   (w_1 . w_2) + (w_1 . w_2) + (w_1 . w_4 + w_2 . w_3 - w_3) . 2    - w_3 - w_4   |
         *            \_                                                                               _/
         *
         *
         */
        ap.limb_subproduct = wire(p, WIRE.W_L) * wire(p, WIRE.W_R_SHIFT) + wire(p, WIRE.W_L_SHIFT) * wire(p, WIRE.W_R);
        ap.non_native_field_gate_2 =
            (wire(p, WIRE.W_L) * wire(p, WIRE.W_4) + wire(p, WIRE.W_R) * wire(p, WIRE.W_O) - wire(p, WIRE.W_O_SHIFT));
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 * LIMB_SIZE;
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 - wire(p, WIRE.W_4_SHIFT);
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 + ap.limb_subproduct;
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 * wire(p, WIRE.Q_4);

        ap.limb_subproduct = ap.limb_subproduct * LIMB_SIZE;
        ap.limb_subproduct = ap.limb_subproduct + (wire(p, WIRE.W_L_SHIFT) * wire(p, WIRE.W_R_SHIFT));
        ap.non_native_field_gate_1 = ap.limb_subproduct;
        ap.non_native_field_gate_1 = ap.non_native_field_gate_1 - (wire(p, WIRE.W_O) + wire(p, WIRE.W_4));
        ap.non_native_field_gate_1 = ap.non_native_field_gate_1 * wire(p, WIRE.Q_O);

        ap.non_native_field_gate_3 = ap.limb_subproduct;
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 + wire(p, WIRE.W_4);
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 - (wire(p, WIRE.W_O_SHIFT) + wire(p, WIRE.W_4_SHIFT));
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 * wire(p, WIRE.Q_M);

        Fr non_native_field_identity =
            ap.non_native_field_gate_1 + ap.non_native_field_gate_2 + ap.non_native_field_gate_3;
        non_native_field_identity = non_native_field_identity * wire(p, WIRE.Q_R);

        // ((((w2' * 2^14 + w1') * 2^14 + w3) * 2^14 + w2) * 2^14 + w1 - w4) * qm
        // deg 2
        ap.limb_accumulator_1 = wire(p, WIRE.W_R_SHIFT) * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_L_SHIFT);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_O);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_R);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_L);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 - wire(p, WIRE.W_4);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * wire(p, WIRE.Q_4);

        // ((((w3' * 2^14 + w2') * 2^14 + w1') * 2^14 + w4) * 2^14 + w3 - w4') * qm
        // deg 2
        ap.limb_accumulator_2 = wire(p, WIRE.W_O_SHIFT) * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_R_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_L_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_4);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_O);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 - wire(p, WIRE.W_4_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * wire(p, WIRE.Q_M);

        Fr limb_accumulator_identity = ap.limb_accumulator_1 + ap.limb_accumulator_2;
        limb_accumulator_identity = limb_accumulator_identity * wire(p, WIRE.Q_O); //  deg 3

        /**
         * MEMORY
         *
         * A RAM memory record contains a tuple of the following fields:
         *  * i: `index` of memory cell being accessed
         *  * t: `timestamp` of memory cell being accessed (used for RAM, set to 0 for ROM)
         *  * v: `value` of memory cell being accessed
         *  * a: `access` type of record. read: 0 = read, 1 = write
         *  * r: `record` of memory cell. record = access + index * eta + timestamp * eta_two + value * eta_three
         *
         * A ROM memory record contains a tuple of the following fields:
         *  * i: `index` of memory cell being accessed
         *  * v: `value1` of memory cell being accessed (ROM tables can store up to 2 values per index)
         *  * v2:`value2` of memory cell being accessed (ROM tables can store up to 2 values per index)
         *  * r: `record` of memory cell. record = index * eta + value2 * eta_two + value1 * eta_three
         *
         *  When performing a read/write access, the values of i, t, v, v2, a, r are stored in the following wires +
         * selectors, depending on whether the gate is a RAM read/write or a ROM read
         *
         *  | gate type | i  | v2/t  |  v | a  | r  |
         *  | --------- | -- | ----- | -- | -- | -- |
         *  | ROM       | w1 | w2    | w3 | -- | w4 |
         *  | RAM       | w1 | w2    | w3 | qc | w4 |
         *
         * (for accesses where `index` is a circuit constant, it is assumed the circuit will apply a copy constraint on
         * `w2` to fix its value)
         *
         *
         */

        /**
         * Memory Record Check
         * Partial degree: 1
         * Total degree: 4
         *
         * A ROM/ROM access gate can be evaluated with the identity:
         *
         * qc + w1 \eta + w2 \eta_two + w3 \eta_three - w4 = 0
         *
         * For ROM gates, qc = 0
         */
        ap.memory_record_check = wire(p, WIRE.W_O) * rp.etaThree;
        ap.memory_record_check = ap.memory_record_check + (wire(p, WIRE.W_R) * rp.etaTwo);
        ap.memory_record_check = ap.memory_record_check + (wire(p, WIRE.W_L) * rp.eta);
        ap.memory_record_check = ap.memory_record_check + wire(p, WIRE.Q_C);
        ap.partial_record_check = ap.memory_record_check; // used in RAM consistency check; deg 1 or 4
        ap.memory_record_check = ap.memory_record_check - wire(p, WIRE.W_4);

        /**
         * Contribution 13 & 14
         * ROM Consistency Check
         * Partial degree: 1
         * Total degree: 4
         *
         * For every ROM read, a set equivalence check is applied between the record witnesses, and a second set of
         * records that are sorted.
         *
         * We apply the following checks for the sorted records:
         *
         * 1. w1, w2, w3 correctly map to 'index', 'v1, 'v2' for a given record value at w4
         * 2. index values for adjacent records are monotonically increasing
         * 3. if, at gate i, index_i == index_{i + 1}, then value1_i == value1_{i + 1} and value2_i == value2_{i + 1}
         *
         */
        ap.index_delta = wire(p, WIRE.W_L_SHIFT) - wire(p, WIRE.W_L);
        ap.record_delta = wire(p, WIRE.W_4_SHIFT) - wire(p, WIRE.W_4);

        ap.index_is_monotonically_increasing = ap.index_delta * ap.index_delta - ap.index_delta; // deg 2

        ap.adjacent_values_match_if_adjacent_indices_match = (ap.index_delta * MINUS_ONE + Fr.wrap(1)) * ap.record_delta; // deg 2

        evals[13] = ap.adjacent_values_match_if_adjacent_indices_match * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R))
            * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5
        evals[14] = ap.index_is_monotonically_increasing * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R))
            * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5

        ap.ROM_consistency_check_identity = ap.memory_record_check * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R)); // deg 3 or 7

        /**
         * Contributions 15,16,17
         * RAM Consistency Check
         *
         * The 'access' type of the record is extracted with the expression `w_4 - ap.partial_record_check`
         * (i.e. for an honest Prover `w1 * eta + w2 * eta^2 + w3 * eta^3 - w4 = access`.
         * This is validated by requiring `access` to be boolean
         *
         * For two adjacent entries in the sorted list if _both_
         *  A) index values match
         *  B) adjacent access value is 0 (i.e. next gate is a READ)
         * then
         *  C) both values must match.
         * The gate boolean check is
         * (A && B) => C  === !(A && B) || C ===  !A || !B || C
         *
         * N.B. it is the responsibility of the circuit writer to ensure that every RAM cell is initialized
         * with a WRITE operation.
         */
        Fr access_type = (wire(p, WIRE.W_4) - ap.partial_record_check); // will be 0 or 1 for honest Prover; deg 1 or 4
        ap.access_check = access_type * access_type - access_type; // check value is 0 or 1; deg 2 or 8

        ap.next_gate_access_type = wire(p, WIRE.W_O_SHIFT) * rp.etaThree;
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_R_SHIFT) * rp.etaTwo);
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_L_SHIFT) * rp.eta);
        ap.next_gate_access_type = wire(p, WIRE.W_4_SHIFT) - ap.next_gate_access_type;

        Fr value_delta = wire(p, WIRE.W_O_SHIFT) - wire(p, WIRE.W_O);
        ap.adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation = (
            ap.index_delta * MINUS_ONE + Fr.wrap(1)
        ) * value_delta * (ap.next_gate_access_type * MINUS_ONE + Fr.wrap(1)); // deg 3 or 6

        // We can't apply the RAM consistency check identity on the final entry in the sorted list (the wires in the
        // next gate would make the identity fail).  We need to validate that its 'access type' bool is correct. Can't
        // do  with an arithmetic gate because of the  `eta` factors. We need to check that the *next* gate's access
        // type is  correct, to cover this edge case
        // deg 2 or 4
        ap.next_gate_access_type_is_boolean =
            ap.next_gate_access_type * ap.next_gate_access_type - ap.next_gate_access_type;

        // Putting it all together...
        evals[15] = ap.adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation
            * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5 or 8
        evals[16] = ap.index_is_monotonically_increasing * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4
        evals[17] = ap.next_gate_access_type_is_boolean * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4 or 6

        ap.RAM_consistency_check_identity = ap.access_check * (wire(p, WIRE.Q_ARITH)); // deg 3 or 9

        /**
         * RAM Timestamp Consistency Check
         *
         * | w1 | w2 | w3 | w4 |
         * | index | timestamp | timestamp_check | -- |
         *
         * Let delta_index = index_{i + 1} - index_{i}
         *
         * Iff delta_index == 0, timestamp_check = timestamp_{i + 1} - timestamp_i
         * Else timestamp_check = 0
         */
        ap.timestamp_delta = wire(p, WIRE.W_R_SHIFT) - wire(p, WIRE.W_R);
        ap.RAM_timestamp_check_identity =
            (ap.index_delta * MINUS_ONE + Fr.wrap(1)) * ap.timestamp_delta - wire(p, WIRE.W_O); // deg 3

        /**
         * Complete Contribution 12
         * The complete RAM/ROM memory identity
         * Partial degree:
         */
        ap.memory_identity = ap.ROM_consistency_check_identity; // deg 3 or 6
        ap.memory_identity =
            ap.memory_identity + ap.RAM_timestamp_check_identity * (wire(p, WIRE.Q_4) * wire(p, WIRE.Q_L)); // deg 4
        ap.memory_identity = ap.memory_identity + ap.memory_record_check * (wire(p, WIRE.Q_M) * wire(p, WIRE.Q_L)); // deg 3 or 6
        ap.memory_identity = ap.memory_identity + ap.RAM_consistency_check_identity; // deg 3 or 9

        // (deg 3 or 9) + (deg 4) + (deg 3)
        ap.auxiliary_identity = ap.memory_identity + non_native_field_identity + limb_accumulator_identity;
        ap.auxiliary_identity = ap.auxiliary_identity * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4 or 10
        evals[12] = ap.auxiliary_identity;
    }

    struct PoseidonExternalParams {
        Fr s1;
        Fr s2;
        Fr s3;
        Fr s4;
        Fr u1;
        Fr u2;
        Fr u3;
        Fr u4;
        Fr t0;
        Fr t1;
        Fr t2;
        Fr t3;
        Fr v1;
        Fr v2;
        Fr v3;
        Fr v4;
        Fr q_pos_by_scaling;
    }

    function accumulatePoseidonExternalRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        PoseidonExternalParams memory ep;

        ep.s1 = wire(p, WIRE.W_L) + wire(p, WIRE.Q_L);
        ep.s2 = wire(p, WIRE.W_R) + wire(p, WIRE.Q_R);
        ep.s3 = wire(p, WIRE.W_O) + wire(p, WIRE.Q_O);
        ep.s4 = wire(p, WIRE.W_4) + wire(p, WIRE.Q_4);

        ep.u1 = ep.s1 * ep.s1 * ep.s1 * ep.s1 * ep.s1;
        ep.u2 = ep.s2 * ep.s2 * ep.s2 * ep.s2 * ep.s2;
        ep.u3 = ep.s3 * ep.s3 * ep.s3 * ep.s3 * ep.s3;
        ep.u4 = ep.s4 * ep.s4 * ep.s4 * ep.s4 * ep.s4;
        // matrix mul v = M_E * u with 14 additions
        ep.t0 = ep.u1 + ep.u2; // u_1 + u_2
        ep.t1 = ep.u3 + ep.u4; // u_3 + u_4
        ep.t2 = ep.u2 + ep.u2 + ep.t1; // 2u_2
        // ep.t2 += ep.t1; // 2u_2 + u_3 + u_4
        ep.t3 = ep.u4 + ep.u4 + ep.t0; // 2u_4
        // ep.t3 += ep.t0; // u_1 + u_2 + 2u_4
        ep.v4 = ep.t1 + ep.t1;
        ep.v4 = ep.v4 + ep.v4 + ep.t3;
        // ep.v4 += ep.t3; // u_1 + u_2 + 4u_3 + 6u_4
        ep.v2 = ep.t0 + ep.t0;
        ep.v2 = ep.v2 + ep.v2 + ep.t2;
        // ep.v2 += ep.t2; // 4u_1 + 6u_2 + u_3 + u_4
        ep.v1 = ep.t3 + ep.v2; // 5u_1 + 7u_2 + u_3 + 3u_4
        ep.v3 = ep.t2 + ep.v4; // u_1 + 3u_2 + 5u_3 + 7u_4

        ep.q_pos_by_scaling = wire(p, WIRE.Q_POSEIDON2_EXTERNAL) * domainSep;
        evals[18] = evals[18] + ep.q_pos_by_scaling * (ep.v1 - wire(p, WIRE.W_L_SHIFT));

        evals[19] = evals[19] + ep.q_pos_by_scaling * (ep.v2 - wire(p, WIRE.W_R_SHIFT));

        evals[20] = evals[20] + ep.q_pos_by_scaling * (ep.v3 - wire(p, WIRE.W_O_SHIFT));

        evals[21] = evals[21] + ep.q_pos_by_scaling * (ep.v4 - wire(p, WIRE.W_4_SHIFT));
    }

    struct PoseidonInternalParams {
        Fr u1;
        Fr u2;
        Fr u3;
        Fr u4;
        Fr u_sum;
        Fr v1;
        Fr v2;
        Fr v3;
        Fr v4;
        Fr s1;
        Fr q_pos_by_scaling;
    }

    function accumulatePoseidonInternalRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        PoseidonInternalParams memory ip;

        Fr[4] memory INTERNAL_MATRIX_DIAGONAL = [
            ValidMoveFrLib.from(0x10dc6e9c006ea38b04b1e03b4bd9490c0d03f98929ca1d7fb56821fd19d3b6e7),
            ValidMoveFrLib.from(0x0c28145b6a44df3e0149b3d0a30b3bb599df9756d4dd9b84a86b38cfb45a740b),
            ValidMoveFrLib.from(0x00544b8338791518b2c7645a50392798b21f75bb60e3596170067d00141cac15),
            ValidMoveFrLib.from(0x222c01175718386f2e2e82eb122789e352e105a3b8fa852613bc534433ee428b)
        ];

        // add round constants
        ip.s1 = wire(p, WIRE.W_L) + wire(p, WIRE.Q_L);

        // apply s-box round
        ip.u1 = ip.s1 * ip.s1 * ip.s1 * ip.s1 * ip.s1;
        ip.u2 = wire(p, WIRE.W_R);
        ip.u3 = wire(p, WIRE.W_O);
        ip.u4 = wire(p, WIRE.W_4);

        // matrix mul with v = M_I * u 4 muls and 7 additions
        ip.u_sum = ip.u1 + ip.u2 + ip.u3 + ip.u4;

        ip.q_pos_by_scaling = wire(p, WIRE.Q_POSEIDON2_INTERNAL) * domainSep;

        ip.v1 = ip.u1 * INTERNAL_MATRIX_DIAGONAL[0] + ip.u_sum;
        evals[22] = evals[22] + ip.q_pos_by_scaling * (ip.v1 - wire(p, WIRE.W_L_SHIFT));

        ip.v2 = ip.u2 * INTERNAL_MATRIX_DIAGONAL[1] + ip.u_sum;
        evals[23] = evals[23] + ip.q_pos_by_scaling * (ip.v2 - wire(p, WIRE.W_R_SHIFT));

        ip.v3 = ip.u3 * INTERNAL_MATRIX_DIAGONAL[2] + ip.u_sum;
        evals[24] = evals[24] + ip.q_pos_by_scaling * (ip.v3 - wire(p, WIRE.W_O_SHIFT));

        ip.v4 = ip.u4 * INTERNAL_MATRIX_DIAGONAL[3] + ip.u_sum;
        evals[25] = evals[25] + ip.q_pos_by_scaling * (ip.v4 - wire(p, WIRE.W_4_SHIFT));
    }

    function scaleAndBatchSubrelations(
        Fr[NUMBER_OF_SUBRELATIONS] memory evaluations,
        Fr[NUMBER_OF_ALPHAS] memory subrelationChallenges
    ) internal pure returns (Fr accumulator) {
        accumulator = accumulator + evaluations[0];

        for (uint256 i = 1; i < NUMBER_OF_SUBRELATIONS; ++i) {
            accumulator = accumulator + evaluations[i] * subrelationChallenges[i - 1];
        }
    }
}

struct ShpleminiIntermediates {
    Fr unshiftedScalar;
    Fr shiftedScalar;
    // Scalar to be multiplied by [1]₁
    Fr constantTermAccumulator;
    // Accumulator for powers of rho
    Fr batchingChallenge;
    // Linear combination of multilinear (sumcheck) evaluations and powers of rho
    Fr batchedEvaluation;
    // 1/(z - r^{2^i}) for i = 0, ..., logSize, dynamically updated
    Fr posInvertedDenominator;
    // 1/(z + r^{2^i}) for i = 0, ..., logSize, dynamically updated
    Fr negInvertedDenominator;
    // v^{2i} * 1/(z - r^{2^i})
    Fr scalingFactorPos;
    // v^{2i+1} * 1/(z + r^{2^i})
    Fr scalingFactorNeg;
    // // Fold_i(r^{2^i}) reconstructed by Verifier
    // Fr[CONST_PROOF_SIZE_LOG_N] foldPosEvaluations;
}

library ValidMoveCommitmentSchemeLib {
    using ValidMoveFrLib for Fr;

    function computeSquares(Fr r) internal pure returns (Fr[CONST_PROOF_SIZE_LOG_N] memory squares) {
        squares[0] = r;
        for (uint256 i = 1; i < CONST_PROOF_SIZE_LOG_N; ++i) {
            squares[i] = squares[i - 1].sqr();
        }
    }

    // Compute the evaluations  A_l(r^{2^l}) for l = 0, ..., m-1
    function computeFoldPosEvaluations(
        Fr[CONST_PROOF_SIZE_LOG_N] memory sumcheckUChallenges,
        Fr batchedEvalAccumulator,
        Fr[CONST_PROOF_SIZE_LOG_N] memory geminiEvaluations,
        Fr[CONST_PROOF_SIZE_LOG_N] memory geminiEvalChallengePowers,
        uint256 logSize
    ) internal view returns (Fr[CONST_PROOF_SIZE_LOG_N] memory foldPosEvaluations) {
        for (uint256 i = CONST_PROOF_SIZE_LOG_N; i > 0; --i) {
            Fr challengePower = geminiEvalChallengePowers[i - 1];
            Fr u = sumcheckUChallenges[i - 1];

            Fr batchedEvalRoundAcc = (
                (challengePower * batchedEvalAccumulator * Fr.wrap(2))
                    - geminiEvaluations[i - 1] * (challengePower * (Fr.wrap(1) - u) - u)
            );
            // Divide by the denominator
            batchedEvalRoundAcc = batchedEvalRoundAcc * (challengePower * (Fr.wrap(1) - u) + u).invert();

            if (i <= logSize) {
                batchedEvalAccumulator = batchedEvalRoundAcc;
                foldPosEvaluations[i - 1] = batchedEvalRoundAcc;
            }
        }

    }
}

interface IVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}


abstract contract BaseHonkVerifier is IVerifier {
    using ValidMoveFrLib for Fr;

    uint256 immutable n;
    uint256 immutable logN;
    uint256 immutable numPublicInputs;

    constructor(uint256 _n, uint256 _logN, uint256 _numPublicInputs) {
        n = _n;
        logN = _logN;
        numPublicInputs = _numPublicInputs;
    }

    error ProofLengthWrong();
    error PublicInputsLengthWrong();
    error SumcheckFailed();
    error ShpleminiFailed();

    // Number of field elements in a ultra honk zero knowledge proof
    uint256 constant PROOF_SIZE = 440;

    function loadVerificationKey() internal pure virtual returns (ValidMoveHonk.VerificationKey memory);

    function verify(bytes calldata proof, bytes32[] calldata publicInputs) public view override returns (bool) {
         // Check the received proof is the expected size where each field element is 32 bytes
        if (proof.length != PROOF_SIZE * 32) {
            revert ProofLengthWrong();
        }

        ValidMoveHonk.VerificationKey memory vk = loadVerificationKey();
        ValidMoveHonk.Proof memory p = ValidMoveTranscriptLib.loadProof(proof);

        if (publicInputs.length != vk.publicInputsSize) {
            revert PublicInputsLengthWrong();
        }

        // Generate the fiat shamir challenges for the whole protocol
        // TODO(https://github.com/AztecProtocol/barretenberg/issues/1281): Add pubInputsOffset to VK or remove entirely.
        Transcript memory t = ValidMoveTranscriptLib.generateTranscript(p, publicInputs, vk.circuitSize, vk.publicInputsSize, /*pubInputsOffset=*/1);

        // Derive public input delta
        // TODO(https://github.com/AztecProtocol/barretenberg/issues/1281): Add pubInputsOffset to VK or remove entirely.
        t.relationParameters.publicInputsDelta = computePublicInputDelta(
            publicInputs, t.relationParameters.beta, t.relationParameters.gamma, /*pubInputsOffset=*/1
        );

        // Sumcheck
        bool sumcheckVerified = verifySumcheck(p, t);
        if (!sumcheckVerified) revert SumcheckFailed();

        bool shpleminiVerified = verifyShplemini(p, vk, t);
        if (!shpleminiVerified) revert ShpleminiFailed();

        return sumcheckVerified && shpleminiVerified; // Boolean condition not required - nice for vanity :)
    }

    function computePublicInputDelta(bytes32[] memory publicInputs, Fr beta, Fr gamma, uint256 offset)
        internal
        view
        returns (Fr publicInputDelta)
    {
        Fr numerator = Fr.wrap(1);
        Fr denominator = Fr.wrap(1);

        Fr numeratorAcc = gamma + (beta * ValidMoveFrLib.from(n + offset));
        Fr denominatorAcc = gamma - (beta * ValidMoveFrLib.from(offset + 1));

        {
            for (uint256 i = 0; i < numPublicInputs; i++) {
                Fr pubInput = ValidMoveFrLib.fromBytes32(publicInputs[i]);

                numerator = numerator * (numeratorAcc + pubInput);
                denominator = denominator * (denominatorAcc + pubInput);

                numeratorAcc = numeratorAcc + beta;
                denominatorAcc = denominatorAcc - beta;
            }
        }

        // Fr delta = numerator / denominator; // TOOO: batch invert later?
        publicInputDelta = ValidMoveFrLib.div(numerator, denominator);
    }

    function verifySumcheck(ValidMoveHonk.Proof memory proof, Transcript memory tp) internal view returns (bool verified) {
        Fr roundTarget;
        Fr powPartialEvaluation = Fr.wrap(1);

        // We perform sumcheck reductions over log n rounds ( the multivariate degree )
        for (uint256 round; round < logN; ++round) {
            Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate = proof.sumcheckUnivariates[round];
            bool valid = checkSum(roundUnivariate, roundTarget);
            if (!valid) revert SumcheckFailed();

            Fr roundChallenge = tp.sumCheckUChallenges[round];

            // Update the round target for the next rounf
            roundTarget = computeNextTargetSum(roundUnivariate, roundChallenge);
            powPartialEvaluation = partiallyEvaluatePOW(tp.gateChallenges[round], powPartialEvaluation, roundChallenge);
        }

        // Last round
        Fr grandHonkRelationSum =
            ValidMoveRelationsLib.accumulateRelationEvaluations(proof.sumcheckEvaluations, tp.relationParameters, tp.alphas, powPartialEvaluation);
        verified = (grandHonkRelationSum == roundTarget);
    }

    function checkSum(Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate, Fr roundTarget)
        internal
        pure
        returns (bool checked)
    {
        Fr totalSum = roundUnivariate[0] + roundUnivariate[1];
        checked = totalSum == roundTarget;
    }

    // Return the new target sum for the next sumcheck round
    function computeNextTargetSum(Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariates, Fr roundChallenge)
        internal
        view
        returns (Fr targetSum)
    {
        // TODO: inline
        Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory BARYCENTRIC_LAGRANGE_DENOMINATORS = [
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffec51),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000002d0),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff11),
            Fr.wrap(0x0000000000000000000000000000000000000000000000000000000000000090),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff71),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000000f0),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffd31),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000013b0)
        ];

        // To compute the next target sum, we evaluate the given univariate at a point u (challenge).

        // Performing Barycentric evaluations
        // Compute B(x)
        Fr numeratorValue = Fr.wrap(1);
        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            numeratorValue = numeratorValue * (roundChallenge - Fr.wrap(i));
        }

        // Calculate domain size N of inverses
        Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory denominatorInverses;
        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            Fr inv = BARYCENTRIC_LAGRANGE_DENOMINATORS[i];
            inv = inv * (roundChallenge - Fr.wrap(i));
            inv = ValidMoveFrLib.invert(inv);
            denominatorInverses[i] = inv;
        }

        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            Fr term = roundUnivariates[i];
            term = term * denominatorInverses[i];
            targetSum = targetSum + term;
        }

        // Scale the sum by the value of B(x)
        targetSum = targetSum * numeratorValue;
    }

    // Univariate evaluation of the monomial ((1-X_l) + X_l.B_l) at the challenge point X_l=u_l
    function partiallyEvaluatePOW(Fr gateChallenge, Fr currentEvaluation, Fr roundChallenge)
        internal
        pure
        returns (Fr newEvaluation)
    {
        Fr univariateEval = Fr.wrap(1) + (roundChallenge * (gateChallenge - Fr.wrap(1)));
        newEvaluation = currentEvaluation * univariateEval;
    }

    function verifyShplemini(ValidMoveHonk.Proof memory proof, ValidMoveHonk.VerificationKey memory vk, Transcript memory tp)
        internal
        view
        returns (bool verified)
    {
        ShpleminiIntermediates memory mem; // stack

        // - Compute vector (r, r², ... , r²⁽ⁿ⁻¹⁾), where n = log_circuit_size
        Fr[CONST_PROOF_SIZE_LOG_N] memory powers_of_evaluation_challenge = ValidMoveCommitmentSchemeLib.computeSquares(tp.geminiR);

        // Arrays hold values that will be linearly combined for the gemini and shplonk batch openings
        Fr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars;
        ValidMoveHonk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory commitments;

        mem.posInvertedDenominator = (tp.shplonkZ - powers_of_evaluation_challenge[0]).invert();
        mem.negInvertedDenominator = (tp.shplonkZ + powers_of_evaluation_challenge[0]).invert();

        mem.unshiftedScalar = mem.posInvertedDenominator + (tp.shplonkNu * mem.negInvertedDenominator);
        mem.shiftedScalar =
            tp.geminiR.invert() * (mem.posInvertedDenominator - (tp.shplonkNu * mem.negInvertedDenominator));

        scalars[0] = Fr.wrap(1);
        commitments[0] = convertProofPoint(proof.shplonkQ);

        mem.batchingChallenge = Fr.wrap(1);
        mem.batchedEvaluation = Fr.wrap(0);

        for (uint256 i = 1; i <= NUMBER_UNSHIFTED; ++i) {
            scalars[i] = mem.unshiftedScalar.neg() * mem.batchingChallenge;
            mem.batchedEvaluation = mem.batchedEvaluation + (proof.sumcheckEvaluations[i - 1] * mem.batchingChallenge);
            mem.batchingChallenge = mem.batchingChallenge * tp.rho;
        }
        // g commitments are accumulated at r
        for (uint256 i = NUMBER_UNSHIFTED + 1; i <= NUMBER_OF_ENTITIES; ++i) {
            scalars[i] = mem.shiftedScalar.neg() * mem.batchingChallenge;
            mem.batchedEvaluation = mem.batchedEvaluation + (proof.sumcheckEvaluations[i - 1] * mem.batchingChallenge);
            mem.batchingChallenge = mem.batchingChallenge * tp.rho;
        }

        commitments[1] = vk.qm;
        commitments[2] = vk.qc;
        commitments[3] = vk.ql;
        commitments[4] = vk.qr;
        commitments[5] = vk.qo;
        commitments[6] = vk.q4;
        commitments[7] = vk.qLookup;
        commitments[8] = vk.qArith;
        commitments[9] = vk.qDeltaRange;
        commitments[10] = vk.qElliptic;
        commitments[11] = vk.qAux;
        commitments[12] = vk.qPoseidon2External;
        commitments[13] = vk.qPoseidon2Internal;
        commitments[14] = vk.s1;
        commitments[15] = vk.s2;
        commitments[16] = vk.s3;
        commitments[17] = vk.s4;
        commitments[18] = vk.id1;
        commitments[19] = vk.id2;
        commitments[20] = vk.id3;
        commitments[21] = vk.id4;
        commitments[22] = vk.t1;
        commitments[23] = vk.t2;
        commitments[24] = vk.t3;
        commitments[25] = vk.t4;
        commitments[26] = vk.lagrangeFirst;
        commitments[27] = vk.lagrangeLast;

        // Accumulate proof points
        commitments[28] = convertProofPoint(proof.w1);
        commitments[29] = convertProofPoint(proof.w2);
        commitments[30] = convertProofPoint(proof.w3);
        commitments[31] = convertProofPoint(proof.w4);
        commitments[32] = convertProofPoint(proof.zPerm);
        commitments[33] = convertProofPoint(proof.lookupInverses);
        commitments[34] = convertProofPoint(proof.lookupReadCounts);
        commitments[35] = convertProofPoint(proof.lookupReadTags);

        // to be Shifted
        commitments[36] = convertProofPoint(proof.w1);
        commitments[37] = convertProofPoint(proof.w2);
        commitments[38] = convertProofPoint(proof.w3);
        commitments[39] = convertProofPoint(proof.w4);
        commitments[40] = convertProofPoint(proof.zPerm);

        // Add contributions from A₀(r) and A₀(-r) to constant_term_accumulator:
        // Compute the evaluations A_l(r^{2^l}) for l = 0, ..., logN - 1
        Fr[CONST_PROOF_SIZE_LOG_N] memory foldPosEvaluations = ValidMoveCommitmentSchemeLib.computeFoldPosEvaluations(
            tp.sumCheckUChallenges,
            mem.batchedEvaluation,
            proof.geminiAEvaluations,
            powers_of_evaluation_challenge,
            logN
        );

        // Compute the Shplonk constant term contributions from A₀(±r)
        mem.constantTermAccumulator = foldPosEvaluations[0] * mem.posInvertedDenominator;
        mem.constantTermAccumulator =
            mem.constantTermAccumulator + (proof.geminiAEvaluations[0] * tp.shplonkNu * mem.negInvertedDenominator);
        mem.batchingChallenge = tp.shplonkNu.sqr();

        // Compute Shplonk constant term contributions from Aₗ(±r^{2ˡ}) for l = 1, ..., m-1;
        // Compute scalar multipliers for each fold commitment
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; ++i) {
            bool dummy_round = i >= (logN - 1);

            if (!dummy_round) {
                // Update inverted denominators
                mem.posInvertedDenominator = (tp.shplonkZ - powers_of_evaluation_challenge[i + 1]).invert();
                mem.negInvertedDenominator = (tp.shplonkZ + powers_of_evaluation_challenge[i + 1]).invert();

                // Compute the scalar multipliers for Aₗ(± r^{2ˡ}) and [Aₗ]
                mem.scalingFactorPos = mem.batchingChallenge * mem.posInvertedDenominator;
                mem.scalingFactorNeg = mem.batchingChallenge * tp.shplonkNu * mem.negInvertedDenominator;
                // [Aₗ] is multiplied by -v^{2l}/(z-r^{2^l}) - v^{2l+1} /(z+ r^{2^l})
                scalars[NUMBER_OF_ENTITIES + 1 + i] = mem.scalingFactorNeg.neg() + mem.scalingFactorPos.neg();

                // Accumulate the const term contribution given by
                // v^{2l} * Aₗ(r^{2ˡ}) /(z-r^{2^l}) + v^{2l+1} * Aₗ(-r^{2ˡ}) /(z+ r^{2^l})
                Fr accumContribution = mem.scalingFactorNeg * proof.geminiAEvaluations[i + 1];
                accumContribution = accumContribution + mem.scalingFactorPos * foldPosEvaluations[i + 1];
                mem.constantTermAccumulator = mem.constantTermAccumulator + accumContribution;
                // Update the running power of v
                mem.batchingChallenge = mem.batchingChallenge * tp.shplonkNu * tp.shplonkNu;
            }

            commitments[NUMBER_OF_ENTITIES + 1 + i] = convertProofPoint(proof.geminiFoldComms[i]);
        }

        // Finalise the batch opening claim
        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = ValidMoveHonk.G1Point({x: 1, y: 2});
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = mem.constantTermAccumulator;

        ValidMoveHonk.G1Point memory quotient_commitment = convertProofPoint(proof.kzgQuotient);

        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = quotient_commitment;
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = tp.shplonkZ; // evaluation challenge

        ValidMoveHonk.G1Point memory P_0 = batchMul(commitments, scalars);
        ValidMoveHonk.G1Point memory P_1 = negateInplace(quotient_commitment);

        return pairing(P_0, P_1);
    }

    // This implementation is the same as above with different constants
    function batchMul(
        ValidMoveHonk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory base,
        Fr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars
    ) internal view returns (ValidMoveHonk.G1Point memory result) {
        uint256 limit = NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2;
        assembly {
            let success := 0x01
            let free := mload(0x40)

            // Write the original into the accumulator
            // Load into memory for ecMUL, leave offset for eccAdd result
            // base is an array of pointers, so we have to dereference them
            mstore(add(free, 0x40), mload(mload(base)))
            mstore(add(free, 0x60), mload(add(0x20, mload(base))))
            // Add scalar
            mstore(add(free, 0x80), mload(scalars))
            success := and(success, staticcall(gas(), 7, add(free, 0x40), 0x60, free, 0x40))

            let count := 0x01
            for {} lt(count, limit) { count := add(count, 1) } {
                // Get loop offsets
                let base_base := add(base, mul(count, 0x20))
                let scalar_base := add(scalars, mul(count, 0x20))

                mstore(add(free, 0x40), mload(mload(base_base)))
                mstore(add(free, 0x60), mload(add(0x20, mload(base_base))))
                // Add scalar
                mstore(add(free, 0x80), mload(scalar_base))

                success := and(success, staticcall(gas(), 7, add(free, 0x40), 0x60, add(free, 0x40), 0x40))
                // accumulator = accumulator + accumulator_2
                success := and(success, staticcall(gas(), 6, free, 0x80, free, 0x40))
            }

            // Return the result - i hate this
            mstore(result, mload(free))
            mstore(add(result, 0x20), mload(add(free, 0x20)))
        }
    }
}

contract ValidMoveHonkVerifier is BaseHonkVerifier(VM_N, VM_LOG_N, VM_NUMBER_OF_PUBLIC_INPUTS) {
     function loadVerificationKey() internal pure override returns (ValidMoveHonk.VerificationKey memory) {
       return ValidMoveVerificationKey.loadVerificationKey();
    }
}
