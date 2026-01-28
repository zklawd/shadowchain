// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.21;

uint256 constant N = 32768;
uint256 constant LOG_N = 15;
uint256 constant NUMBER_OF_PUBLIC_INPUTS = 3;
library ClaimArtifactVerificationKey {
    function loadVerificationKey() internal pure returns (ClaimArtifactHonk.VerificationKey memory) {
        ClaimArtifactHonk.VerificationKey memory vk = ClaimArtifactHonk.VerificationKey({
            circuitSize: uint256(32768),
            logCircuitSize: uint256(15),
            publicInputsSize: uint256(3),
            ql: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2201e4f537add1f68b28fd98191cacf9a2ca8d68f61cce01f646c08841e29ef7),
               y: uint256(0x03378e94140685e7240f04f28a3c0951512c21218bde9918e8f330600c58d75e)
            }),
            qr: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2a9dadd52eca0b96180b8f9786e2aa78cbfd14a6e9d296395975c5ceae322c60),
               y: uint256(0x1dfd7371c7e7503ee15c2fe928a35857a07945c3775fa228a56628e972499825)
            }),
            qo: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x1489e544e002b35363a611b003f8f34d4eab41910c79e358b19561a0c2b86a74),
               y: uint256(0x2f25d10c537c11b4c207ffca64d10dbb0043238420564377b436b85760ba992e)
            }),
            q4: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x108bccd9c2660c9694cbe050eda97684e692bc24c177a46ce5a699db407e5024),
               y: uint256(0x187e4be83e22302ddd0c6d3344ad0e71e7a0e211cf7f5506296747a012e8a9b7)
            }),
            qm: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x00ac6c565d18565315c3bcf77a43cc3debd05e4e0b176382303e7f6c69b57a79),
               y: uint256(0x062eeb40ea42e07877d457294f8aa8c91fa40b4ea70ab3b293eda5d8d36fb1f2)
            }),
            qc: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0a941b18531e28e7faa73cfb48ea8d2ddefa9b5cf59460ee6546904ed39f1fc0),
               y: uint256(0x22fb8bb8a5772b7a8b06955b9aeec4cc518f4e8f9eb2d4ff8de9665b0f6ba43b)
            }),
            qArith: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0ce30773325d56f4add1bbaa76c1e3b24ed5ca590201c8a5de56d0f6b138aa74),
               y: uint256(0x20dff5fe07c5b3f889b56a1b22a5aac012561dca83b3b6f193ce4be6400d336c)
            }),
            qDeltaRange: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x18adbe9a7e8ff44a01b134c84fd8b17a63c863bdb1429f96b4cfe69b83d9e223),
               y: uint256(0x163a9db05c138a406e6fbb0880ba1da1c5dd6e7cebafef77b203ce2019f973d0)
            }),
            qElliptic: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0a86bdd9b6bcbf765657a8c47012f1500bf533bf59d30e82d49c12d92521b0c7),
               y: uint256(0x091bdf9bc04d9bb4617569a536db3b7c586e21ec8659db0498bf5f5a6904bcda)
            }),
            qAux: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x07be106a91179a1cb44c6eeeeb7ac6ac92f5ab7b6fd56fcbc28f8223f7b2bd04),
               y: uint256(0x0302f4454c69978ff80036ba10fcc913b1759b522be7afcd6b9ebf536ca29aa2)
            }),
            qLookup: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x262383ddbec77935db846e338f109986e78d9db0ed3bd37b7dc5399262d2a0b5),
               y: uint256(0x05bbc3fb5bafbb1820b2f69e1e0f082b0b68a9c340e52c2cdfa9974a0f36e354)
            }),
            qPoseidon2External: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x03232a27ca5240635dd9c36679032ba76ba6be31a199c9069033ddcacbdcd725),
               y: uint256(0x154bf0b1bc53cd0727ce872e0c22e4e3aabcd873b50b7879a3c5b72b7d96f1df)
            }),
            qPoseidon2Internal: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2a0280bda40155ae2d706fb250dd883558d8f6992bf56ef1b0841bb35b4828b0),
               y: uint256(0x1464ee980f9e0147fd8bb28add246d9d9d1fbf396f3efb9dfb7f168195bbad60)
            }),
            s1: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0064f8f40b2c379d8154c9222fedc5ccf10c9925b09b1944e65eef572c59cded),
               y: uint256(0x0e1922537ab3f893e3ae11f08933612819fc0a9ddcc6dd114559d4fbc67230f9)
            }),
            s2: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2f906daad085d3a3fa041e00f9ca206143811c6d8b9d2a3584ecb5609ddded2d),
               y: uint256(0x08ee707d52a87f4dbf6dface052eb44ebcce2e3db79bbe470a020c3e15f4a3f5)
            }),
            s3: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x298ed0b5015279c5e53c2874224f05522fb7f19efec77b4680e06fa27227e7ae),
               y: uint256(0x035d151f0c4bd0ac9a0514d7ebaa5e7412f7337390e2e8e5e4747a2656cd5036)
            }),
            s4: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0890c90b334897a57d89e62643e069dbec491ade982ec95a15acdbced5528cd2),
               y: uint256(0x2ef4da939a226495f3234930c350037a4bdc65ce0dd55210c03c0d08b6d23c15)
            }),
            t1: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x1ff7bc030e15b3e676aeb07e636c342adfd47f9d5b6dc52cd3676f0b106f70f1),
               y: uint256(0x0061e6ce7248a9f101e13fe9b3d473313759d8d68b00dd14f81b7b56bdd0bb99)
            }),
            t2: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x09937e347b7f498b2125d1615bcc9888355aa55567cb53139d32cc74d15821ee),
               y: uint256(0x27844e16a6a5fe154a1a3147b64e8d1eebf89a8f8a24ed8cabf022b58db43ac7)
            }),
            t3: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2860f9b436ef64aaf3cc7da935218d1fc1963881262fa58734572775d529d0a2),
               y: uint256(0x06265d3049abe3509cd30718e79d87e32f6bc8457758cd414ef838e42f9735c5)
            }),
            t4: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x09bfc44d11fa351a2ffa19bed03d348404ab6acf5ad65353d4c84612f64a013f),
               y: uint256(0x19e5488010a0e9c3fbd14c0869cf996a7e7933f6a2ac772b266cabd8e936c292)
            }),
            id1: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0f0445f6fe9fcd68e1633f610d1458ca7aa0c63f1d176b9d060037d705b8ac4d),
               y: uint256(0x21884ba3ac1cce469b7a86fb28b6b173e49fd17d9dae110b671883c12793dc4d)
            }),
            id2: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x214596a088d5bdd48ebee13c2b6a0c84798ede31af87e0d5161fb36e01f27d17),
               y: uint256(0x1d28fb393128fe6334fda0099d2e325b368aed4db55fbf3e9fdb214dcc41632a)
            }),
            id3: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x1b257c3bf95c2a6ca0904ffb52648f67043a98548cc56ed5e1951fcd4c7c0eb5),
               y: uint256(0x1f5f00626a4585b556a46c9febe57152deb5421b98776d384b667b3fe8e3a39e)
            }),
            id4: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x065b3d22b8ce8c41b03b7f5e4c91ab26b9805aed948fcb545977683c9c0ae5fd),
               y: uint256(0x0a996e7b3abcf6db4d30b8c9a1424269fbc3706ff167878e45cfd98f7c8bfcc1)
            }),
            lagrangeFirst: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x2501f325add0dffcd82f2e4e2d4329088eff8709dfd603918bb0d0beae5c617a),
               y: uint256(0x064a992aa4820a261cdccae0384b18f8e6afef14a21347f1cef5e7f87bcdf72e)
            }),
            lagrangeLast: ClaimArtifactHonk.G1Point({ 
               x: uint256(0x0437631a3d9cbfac8f5f7492fcfd4f44d0fd2add2f1c6ae587bee7d24f060572),
               y: uint256(0x0100000000000000000000000000000000000000000000000000000000000000)
            })
        });
        return vk;
    }
}

pragma solidity ^0.8.27;

type ClaimArtifactFr is uint256;

using { add as + } for ClaimArtifactFr global;
using { sub as - } for ClaimArtifactFr global;
using { mul as * } for ClaimArtifactFr global;
using { exp as ^ } for ClaimArtifactFr global;
using { notEqual as != } for ClaimArtifactFr global;
using { equal as == } for ClaimArtifactFr global;

uint256 constant MODULUS =
    21888242871839275222246405745257275088548364400416034343698204186575808495617; // Prime field order

ClaimArtifactFr constant MINUS_ONE = ClaimArtifactFr.wrap(MODULUS - 1);

// Instantiation
library ClaimArtifactFrLib
{
    function from(uint256 value) internal pure returns(ClaimArtifactFr)
    {
        return ClaimArtifactFr.wrap(value % MODULUS);
    }

    function fromBytes32(bytes32 value) internal pure returns(ClaimArtifactFr)
    {
        return ClaimArtifactFr.wrap(uint256(value) % MODULUS);
    }

    function toBytes32(ClaimArtifactFr value) internal pure returns(bytes32)
    {
        return bytes32(ClaimArtifactFr.unwrap(value));
    }

    function invert(ClaimArtifactFr value) internal view returns(ClaimArtifactFr)
    {
        uint256 v = ClaimArtifactFr.unwrap(value);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly ("memory-safe") {
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

        return ClaimArtifactFr.wrap(result);
    }

    function pow(ClaimArtifactFr base, uint256 v) internal view returns(ClaimArtifactFr)
    {
        uint256 b = ClaimArtifactFr.unwrap(base);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly ("memory-safe") {
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

        return ClaimArtifactFr.wrap(result);
    }

    function div(ClaimArtifactFr numerator, ClaimArtifactFr denominator) internal view returns(ClaimArtifactFr)
    {
        return numerator * invert(denominator);
    }

    function sqr(ClaimArtifactFr value) internal pure returns (ClaimArtifactFr) {
        return value * value;
    }

    function unwrap(ClaimArtifactFr value) internal pure returns (uint256) {
        return ClaimArtifactFr.unwrap(value);
    }

    function neg(ClaimArtifactFr value) internal pure returns (ClaimArtifactFr) {
        return ClaimArtifactFr.wrap(MODULUS - ClaimArtifactFr.unwrap(value));
    }
}

// Free functions
function add(ClaimArtifactFr a, ClaimArtifactFr b) pure returns(ClaimArtifactFr)
{
    return ClaimArtifactFr.wrap(addmod(ClaimArtifactFr.unwrap(a), ClaimArtifactFr.unwrap(b), MODULUS));
}

function mul(ClaimArtifactFr a, ClaimArtifactFr b) pure returns(ClaimArtifactFr)
{
    return ClaimArtifactFr.wrap(mulmod(ClaimArtifactFr.unwrap(a), ClaimArtifactFr.unwrap(b), MODULUS));
}

function sub(ClaimArtifactFr a, ClaimArtifactFr b) pure returns(ClaimArtifactFr)
{
    return ClaimArtifactFr.wrap(addmod(ClaimArtifactFr.unwrap(a), MODULUS - ClaimArtifactFr.unwrap(b), MODULUS));
}

function exp(ClaimArtifactFr base, ClaimArtifactFr exponent) pure returns(ClaimArtifactFr)
{
    if (ClaimArtifactFr.unwrap(exponent) == 0) return ClaimArtifactFr.wrap(1);

    for (uint256 i = 1; i < ClaimArtifactFr.unwrap(exponent); i += i) {
        base = base * base;
    }
    return base;
}

function notEqual(ClaimArtifactFr a, ClaimArtifactFr b) pure returns(bool)
{
    return ClaimArtifactFr.unwrap(a) != ClaimArtifactFr.unwrap(b);
}

function equal(ClaimArtifactFr a, ClaimArtifactFr b) pure returns(bool)
{
    return ClaimArtifactFr.unwrap(a) == ClaimArtifactFr.unwrap(b);
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

library ClaimArtifactHonk {
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
        ClaimArtifactFr eta;
        ClaimArtifactFr etaTwo;
        ClaimArtifactFr etaThree;
        ClaimArtifactFr beta;
        ClaimArtifactFr gamma;
        // derived
        ClaimArtifactFr publicInputsDelta;
    }


    struct Proof {
        // Free wires
        ClaimArtifactHonk.G1ProofPoint w1;
        ClaimArtifactHonk.G1ProofPoint w2;
        ClaimArtifactHonk.G1ProofPoint w3;
        ClaimArtifactHonk.G1ProofPoint w4;
        // Lookup helpers - Permutations
        ClaimArtifactHonk.G1ProofPoint zPerm;
        // Lookup helpers - logup
        ClaimArtifactHonk.G1ProofPoint lookupReadCounts;
        ClaimArtifactHonk.G1ProofPoint lookupReadTags;
        ClaimArtifactHonk.G1ProofPoint lookupInverses;
        // Sumcheck
        ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH][CONST_PROOF_SIZE_LOG_N] sumcheckUnivariates;
        ClaimArtifactFr[NUMBER_OF_ENTITIES] sumcheckEvaluations;
        // Shplemini
        ClaimArtifactHonk.G1ProofPoint[CONST_PROOF_SIZE_LOG_N - 1] geminiFoldComms;
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] geminiAEvaluations;
        ClaimArtifactHonk.G1ProofPoint shplonkQ;
        ClaimArtifactHonk.G1ProofPoint kzgQuotient;
    }
}

// Transcript library to generate fiat shamir challenges
struct Transcript {
    // Oink
    ClaimArtifactHonk.RelationParameters relationParameters;
    ClaimArtifactFr[NUMBER_OF_ALPHAS] alphas;
    ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] gateChallenges;
    // Sumcheck
    ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] sumCheckUChallenges;
    // Gemini
    ClaimArtifactFr rho;
    ClaimArtifactFr geminiR;
    // Shplonk
    ClaimArtifactFr shplonkNu;
    ClaimArtifactFr shplonkZ;
}

library TranscriptLib {
    function generateTranscript(ClaimArtifactHonk.Proof memory proof, bytes32[] calldata publicInputs, uint256 circuitSize, uint256 publicInputsSize, uint256 pubInputsOffset)
        internal
        pure
        returns (Transcript memory t)
    {
        ClaimArtifactFr previousChallenge;
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

    function splitChallenge(ClaimArtifactFr challenge) internal pure returns (ClaimArtifactFr first, ClaimArtifactFr second) {
        uint256 challengeU256 = uint256(ClaimArtifactFr.unwrap(challenge));
        uint256 lo = challengeU256 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 hi = challengeU256 >> 128;
        first = ClaimArtifactFrLib.fromBytes32(bytes32(lo));
        second = ClaimArtifactFrLib.fromBytes32(bytes32(hi));
    }

    function generateRelationParametersChallenges(
        ClaimArtifactHonk.Proof memory proof,
        bytes32[] calldata publicInputs,
        uint256 circuitSize,
        uint256 publicInputsSize,
        uint256 pubInputsOffset,
        ClaimArtifactFr previousChallenge
    ) internal pure returns (ClaimArtifactHonk.RelationParameters memory rp, ClaimArtifactFr nextPreviousChallenge) {
        (rp.eta, rp.etaTwo, rp.etaThree, previousChallenge) =
            generateEtaChallenge(proof, publicInputs, circuitSize, publicInputsSize, pubInputsOffset);

        (rp.beta, rp.gamma, nextPreviousChallenge) = generateBetaAndGammaChallenges(previousChallenge, proof);

    }

    function generateEtaChallenge(ClaimArtifactHonk.Proof memory proof, bytes32[] calldata publicInputs, uint256 circuitSize, uint256 publicInputsSize, uint256 pubInputsOffset)
        internal
        pure
        returns (ClaimArtifactFr eta, ClaimArtifactFr etaTwo, ClaimArtifactFr etaThree, ClaimArtifactFr previousChallenge)
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

        previousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(round0)));
        (eta, etaTwo) = splitChallenge(previousChallenge);
        previousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(ClaimArtifactFr.unwrap(previousChallenge))));
        ClaimArtifactFr unused;
        (etaThree, unused) = splitChallenge(previousChallenge);
    }

    function generateBetaAndGammaChallenges(ClaimArtifactFr previousChallenge, ClaimArtifactHonk.Proof memory proof)
        internal
        pure
        returns (ClaimArtifactFr beta, ClaimArtifactFr gamma, ClaimArtifactFr nextPreviousChallenge)
    {
        bytes32[13] memory round1;
        round1[0] = ClaimArtifactFrLib.toBytes32(previousChallenge);
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

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(round1)));
        (beta, gamma) = splitChallenge(nextPreviousChallenge);
    }

    // Alpha challenges non-linearise the gate contributions
    function generateAlphaChallenges(ClaimArtifactFr previousChallenge, ClaimArtifactHonk.Proof memory proof)
        internal
        pure
        returns (ClaimArtifactFr[NUMBER_OF_ALPHAS] memory alphas, ClaimArtifactFr nextPreviousChallenge)
    {
        // Generate the original sumcheck alpha 0 by hashing zPerm and zLookup
        uint256[9] memory alpha0;
        alpha0[0] = ClaimArtifactFr.unwrap(previousChallenge);
        alpha0[1] = proof.lookupInverses.x_0;
        alpha0[2] = proof.lookupInverses.x_1;
        alpha0[3] = proof.lookupInverses.y_0;
        alpha0[4] = proof.lookupInverses.y_1;
        alpha0[5] = proof.zPerm.x_0;
        alpha0[6] = proof.zPerm.x_1;
        alpha0[7] = proof.zPerm.y_0;
        alpha0[8] = proof.zPerm.y_1;

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(alpha0)));
        (alphas[0], alphas[1]) = splitChallenge(nextPreviousChallenge);

        for (uint256 i = 1; i < NUMBER_OF_ALPHAS / 2; i++) {
            nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(ClaimArtifactFr.unwrap(nextPreviousChallenge))));
            (alphas[2 * i], alphas[2 * i + 1]) = splitChallenge(nextPreviousChallenge);
        }
        if (((NUMBER_OF_ALPHAS & 1) == 1) && (NUMBER_OF_ALPHAS > 2)) {
            nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(ClaimArtifactFr.unwrap(nextPreviousChallenge))));
            ClaimArtifactFr unused;
            (alphas[NUMBER_OF_ALPHAS - 1], unused) = splitChallenge(nextPreviousChallenge);
        }
    }

    function generateGateChallenges(ClaimArtifactFr previousChallenge)
        internal
        pure
        returns (ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory gateChallenges, ClaimArtifactFr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            previousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(ClaimArtifactFr.unwrap(previousChallenge))));
            ClaimArtifactFr unused;
            (gateChallenges[i], unused) = splitChallenge(previousChallenge);
        }
        nextPreviousChallenge = previousChallenge;
    }

    function generateSumcheckChallenges(ClaimArtifactHonk.Proof memory proof, ClaimArtifactFr prevChallenge)
        internal
        pure
        returns (ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory sumcheckChallenges, ClaimArtifactFr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH + 1] memory univariateChal;
            univariateChal[0] = prevChallenge;

            for (uint256 j = 0; j < BATCHED_RELATION_PARTIAL_LENGTH; j++) {
                univariateChal[j + 1] = proof.sumcheckUnivariates[i][j];
            }
            prevChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(univariateChal)));
            ClaimArtifactFr unused;
            (sumcheckChallenges[i], unused) = splitChallenge(prevChallenge);
        }
        nextPreviousChallenge = prevChallenge;
    }

    function generateRhoChallenge(ClaimArtifactHonk.Proof memory proof, ClaimArtifactFr prevChallenge)
        internal
        pure
        returns (ClaimArtifactFr rho, ClaimArtifactFr nextPreviousChallenge)
    {
        ClaimArtifactFr[NUMBER_OF_ENTITIES + 1] memory rhoChallengeElements;
        rhoChallengeElements[0] = prevChallenge;

        for (uint256 i = 0; i < NUMBER_OF_ENTITIES; i++) {
            rhoChallengeElements[i + 1] = proof.sumcheckEvaluations[i];
        }

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(rhoChallengeElements)));
        ClaimArtifactFr unused;
        (rho, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateGeminiRChallenge(ClaimArtifactHonk.Proof memory proof, ClaimArtifactFr prevChallenge)
        internal
        pure
        returns (ClaimArtifactFr geminiR, ClaimArtifactFr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N - 1) * 4 + 1] memory gR;
        gR[0] = ClaimArtifactFr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; i++) {
            gR[1 + i * 4] = proof.geminiFoldComms[i].x_0;
            gR[2 + i * 4] = proof.geminiFoldComms[i].x_1;
            gR[3 + i * 4] = proof.geminiFoldComms[i].y_0;
            gR[4 + i * 4] = proof.geminiFoldComms[i].y_1;
        }

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(gR)));
        ClaimArtifactFr unused;
        (geminiR, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkNuChallenge(ClaimArtifactHonk.Proof memory proof, ClaimArtifactFr prevChallenge)
        internal
        pure
        returns (ClaimArtifactFr shplonkNu, ClaimArtifactFr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N) + 1] memory shplonkNuChallengeElements;
        shplonkNuChallengeElements[0] = ClaimArtifactFr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            shplonkNuChallengeElements[i + 1] = ClaimArtifactFr.unwrap(proof.geminiAEvaluations[i]);
        }

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(shplonkNuChallengeElements)));
        ClaimArtifactFr unused;
        (shplonkNu, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkZChallenge(ClaimArtifactHonk.Proof memory proof, ClaimArtifactFr prevChallenge)
        internal
        pure
        returns (ClaimArtifactFr shplonkZ, ClaimArtifactFr nextPreviousChallenge)
    {
        uint256[5] memory shplonkZChallengeElements;
        shplonkZChallengeElements[0] = ClaimArtifactFr.unwrap(prevChallenge);

        shplonkZChallengeElements[1] = proof.shplonkQ.x_0;
        shplonkZChallengeElements[2] = proof.shplonkQ.x_1;
        shplonkZChallengeElements[3] = proof.shplonkQ.y_0;
        shplonkZChallengeElements[4] = proof.shplonkQ.y_1;

        nextPreviousChallenge = ClaimArtifactFrLib.fromBytes32(keccak256(abi.encodePacked(shplonkZChallengeElements)));
        ClaimArtifactFr unused;
        (shplonkZ, unused) = splitChallenge(nextPreviousChallenge);
    }

    function loadProof(bytes calldata proof) internal pure returns (ClaimArtifactHonk.Proof memory p) {
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


// ClaimArtifactFr utility

function bytesToFr(bytes calldata proofSection) pure returns (ClaimArtifactFr scalar) {
    require(proofSection.length == 0x20, "invalid bytes scalar");
    scalar = ClaimArtifactFrLib.fromBytes32(bytes32(proofSection));
}

// EC Point utilities
function convertProofPoint(ClaimArtifactHonk.G1ProofPoint memory input) pure returns (ClaimArtifactHonk.G1Point memory) {
    return ClaimArtifactHonk.G1Point({x: input.x_0 | (input.x_1 << 136), y: input.y_0 | (input.y_1 << 136)});
}

function bytesToG1ProofPoint(bytes calldata proofSection) pure returns (ClaimArtifactHonk.G1ProofPoint memory point) {
    require(proofSection.length == 0x80, "invalid bytes point");
    point = ClaimArtifactHonk.G1ProofPoint({
        x_0: uint256(bytes32(proofSection[0x00:0x20])),
        x_1: uint256(bytes32(proofSection[0x20:0x40])),
        y_0: uint256(bytes32(proofSection[0x40:0x60])),
        y_1: uint256(bytes32(proofSection[0x60:0x80]))
    });
}

function negateInplace(ClaimArtifactHonk.G1Point memory point) pure returns (ClaimArtifactHonk.G1Point memory) {
    point.y = (Q - point.y) % Q;
    return point;
}

 function pairing(ClaimArtifactHonk.G1Point memory rhs, ClaimArtifactHonk.G1Point memory lhs) view returns (bool) {
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


library RelationsLib {
    ClaimArtifactFr internal constant GRUMPKIN_CURVE_B_PARAMETER_NEGATED = ClaimArtifactFr.wrap(17); // -(-17)

    function accumulateRelationEvaluations(
         ClaimArtifactFr[NUMBER_OF_ENTITIES] memory purportedEvaluations,
        ClaimArtifactHonk.RelationParameters memory rp,
        ClaimArtifactFr[NUMBER_OF_ALPHAS] memory alphas,
        ClaimArtifactFr powPartialEval
    ) internal pure returns (ClaimArtifactFr accumulator) {
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evaluations;

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
    function wire(ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p, WIRE _wire) internal pure returns (ClaimArtifactFr) {
        return p[uint256(_wire)];
    }

    uint256 internal constant NEG_HALF_MODULO_P = 0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000000;
    /**
     * Ultra Arithmetic Relation
     *
     */
    function accumulateArithmeticRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        // Relation 0
        ClaimArtifactFr q_arith = wire(p, WIRE.Q_ARITH);
        {
            ClaimArtifactFr neg_half = ClaimArtifactFr.wrap(NEG_HALF_MODULO_P);

            ClaimArtifactFr accum = (q_arith - ClaimArtifactFr.wrap(3)) * (wire(p, WIRE.Q_M) * wire(p, WIRE.W_R) * wire(p, WIRE.W_L)) * neg_half;
            accum = accum + (wire(p, WIRE.Q_L) * wire(p, WIRE.W_L)) + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_R))
                + (wire(p, WIRE.Q_O) * wire(p, WIRE.W_O)) + (wire(p, WIRE.Q_4) * wire(p, WIRE.W_4)) + wire(p, WIRE.Q_C);
            accum = accum + (q_arith - ClaimArtifactFr.wrap(1)) * wire(p, WIRE.W_4_SHIFT);
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[0] = accum;
        }

        // Relation 1
        {
            ClaimArtifactFr accum = wire(p, WIRE.W_L) + wire(p, WIRE.W_4) - wire(p, WIRE.W_L_SHIFT) + wire(p, WIRE.Q_M);
            accum = accum * (q_arith - ClaimArtifactFr.wrap(2));
            accum = accum * (q_arith - ClaimArtifactFr.wrap(1));
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[1] = accum;
        }
    }

    function accumulatePermutationRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactHonk.RelationParameters memory rp,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        ClaimArtifactFr grand_product_numerator;
        ClaimArtifactFr grand_product_denominator;

        {
            ClaimArtifactFr num = wire(p, WIRE.W_L) + wire(p, WIRE.ID_1) * rp.beta + rp.gamma;
            num = num * (wire(p, WIRE.W_R) + wire(p, WIRE.ID_2) * rp.beta + rp.gamma);
            num = num * (wire(p, WIRE.W_O) + wire(p, WIRE.ID_3) * rp.beta + rp.gamma);
            num = num * (wire(p, WIRE.W_4) + wire(p, WIRE.ID_4) * rp.beta + rp.gamma);

            grand_product_numerator = num;
        }
        {
            ClaimArtifactFr den = wire(p, WIRE.W_L) + wire(p, WIRE.SIGMA_1) * rp.beta + rp.gamma;
            den = den * (wire(p, WIRE.W_R) + wire(p, WIRE.SIGMA_2) * rp.beta + rp.gamma);
            den = den * (wire(p, WIRE.W_O) + wire(p, WIRE.SIGMA_3) * rp.beta + rp.gamma);
            den = den * (wire(p, WIRE.W_4) + wire(p, WIRE.SIGMA_4) * rp.beta + rp.gamma);

            grand_product_denominator = den;
        }

        // Contribution 2
        {
            ClaimArtifactFr acc = (wire(p, WIRE.Z_PERM) + wire(p, WIRE.LAGRANGE_FIRST)) * grand_product_numerator;

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
            ClaimArtifactFr acc = (wire(p, WIRE.LAGRANGE_LAST) * wire(p, WIRE.Z_PERM_SHIFT)) * domainSep;
            evals[3] = acc;
        }
    }

    function accumulateLogDerivativeLookupRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactHonk.RelationParameters memory rp,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        ClaimArtifactFr write_term;
        ClaimArtifactFr read_term;

        // Calculate the write term (the table accumulation)
        {
            write_term = wire(p, WIRE.TABLE_1) + rp.gamma + (wire(p, WIRE.TABLE_2) * rp.eta)
                + (wire(p, WIRE.TABLE_3) * rp.etaTwo) + (wire(p, WIRE.TABLE_4) * rp.etaThree);
        }

        // Calculate the write term
        {
            ClaimArtifactFr derived_entry_1 = wire(p, WIRE.W_L) + rp.gamma + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_L_SHIFT));
            ClaimArtifactFr derived_entry_2 = wire(p, WIRE.W_R) + wire(p, WIRE.Q_M) * wire(p, WIRE.W_R_SHIFT);
            ClaimArtifactFr derived_entry_3 = wire(p, WIRE.W_O) + wire(p, WIRE.Q_C) * wire(p, WIRE.W_O_SHIFT);

            read_term = derived_entry_1 + (derived_entry_2 * rp.eta) + (derived_entry_3 * rp.etaTwo)
                + (wire(p, WIRE.Q_O) * rp.etaThree);
        }

        ClaimArtifactFr read_inverse = wire(p, WIRE.LOOKUP_INVERSES) * write_term;
        ClaimArtifactFr write_inverse = wire(p, WIRE.LOOKUP_INVERSES) * read_term;

        ClaimArtifactFr inverse_exists_xor = wire(p, WIRE.LOOKUP_READ_TAGS) + wire(p, WIRE.Q_LOOKUP)
            - (wire(p, WIRE.LOOKUP_READ_TAGS) * wire(p, WIRE.Q_LOOKUP));

        // Inverse calculated correctly relation
        ClaimArtifactFr accumulatorNone = read_term * write_term * wire(p, WIRE.LOOKUP_INVERSES) - inverse_exists_xor;
        accumulatorNone = accumulatorNone * domainSep;

        // Inverse
        ClaimArtifactFr accumulatorOne = wire(p, WIRE.Q_LOOKUP) * read_inverse - wire(p, WIRE.LOOKUP_READ_COUNTS) * write_inverse;

        evals[4] = accumulatorNone;
        evals[5] = accumulatorOne;
    }

    function accumulateDeltaRangeRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        ClaimArtifactFr minus_one = ClaimArtifactFr.wrap(0) - ClaimArtifactFr.wrap(1);
        ClaimArtifactFr minus_two = ClaimArtifactFr.wrap(0) - ClaimArtifactFr.wrap(2);
        ClaimArtifactFr minus_three = ClaimArtifactFr.wrap(0) - ClaimArtifactFr.wrap(3);

        // Compute wire differences
        ClaimArtifactFr delta_1 = wire(p, WIRE.W_R) - wire(p, WIRE.W_L);
        ClaimArtifactFr delta_2 = wire(p, WIRE.W_O) - wire(p, WIRE.W_R);
        ClaimArtifactFr delta_3 = wire(p, WIRE.W_4) - wire(p, WIRE.W_O);
        ClaimArtifactFr delta_4 = wire(p, WIRE.W_L_SHIFT) - wire(p, WIRE.W_4);

        // Contribution 6
        {
            ClaimArtifactFr acc = delta_1;
            acc = acc * (delta_1 + minus_one);
            acc = acc * (delta_1 + minus_two);
            acc = acc * (delta_1 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[6] = acc;
        }

        // Contribution 7
        {
            ClaimArtifactFr acc = delta_2;
            acc = acc * (delta_2 + minus_one);
            acc = acc * (delta_2 + minus_two);
            acc = acc * (delta_2 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[7] = acc;
        }

        // Contribution 8
        {
            ClaimArtifactFr acc = delta_3;
            acc = acc * (delta_3 + minus_one);
            acc = acc * (delta_3 + minus_two);
            acc = acc * (delta_3 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[8] = acc;
        }

        // Contribution 9
        {
            ClaimArtifactFr acc = delta_4;
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
        ClaimArtifactFr x_1;
        ClaimArtifactFr y_1;
        ClaimArtifactFr x_2;
        ClaimArtifactFr y_2;
        ClaimArtifactFr y_3;
        ClaimArtifactFr x_3;
        // push accumulators into memory
        ClaimArtifactFr x_double_identity;
    }

    function accumulateEllipticRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        EllipticParams memory ep;
        ep.x_1 = wire(p, WIRE.W_R);
        ep.y_1 = wire(p, WIRE.W_O);

        ep.x_2 = wire(p, WIRE.W_L_SHIFT);
        ep.y_2 = wire(p, WIRE.W_4_SHIFT);
        ep.y_3 = wire(p, WIRE.W_O_SHIFT);
        ep.x_3 = wire(p, WIRE.W_R_SHIFT);

        ClaimArtifactFr q_sign = wire(p, WIRE.Q_L);
        ClaimArtifactFr q_is_double = wire(p, WIRE.Q_M);

        // Contribution 10 point addition, x-coordinate check
        // q_elliptic * (x3 + x2 + x1)(x2 - x1)(x2 - x1) - y2^2 - y1^2 + 2(y2y1)*q_sign = 0
        ClaimArtifactFr x_diff = (ep.x_2 - ep.x_1);
        ClaimArtifactFr y1_sqr = (ep.y_1 * ep.y_1);
        {
            // Move to top
            ClaimArtifactFr partialEval = domainSep;

            ClaimArtifactFr y2_sqr = (ep.y_2 * ep.y_2);
            ClaimArtifactFr y1y2 = ep.y_1 * ep.y_2 * q_sign;
            ClaimArtifactFr x_add_identity = (ep.x_3 + ep.x_2 + ep.x_1);
            x_add_identity = x_add_identity * x_diff * x_diff;
            x_add_identity = x_add_identity - y2_sqr - y1_sqr + y1y2 + y1y2;

            evals[10] = x_add_identity * partialEval * wire(p, WIRE.Q_ELLIPTIC) * (ClaimArtifactFr.wrap(1) - q_is_double);
        }

        // Contribution 11 point addition, x-coordinate check
        // q_elliptic * (q_sign * y1 + y3)(x2 - x1) + (x3 - x1)(y2 - q_sign * y1) = 0
        {
            ClaimArtifactFr y1_plus_y3 = ep.y_1 + ep.y_3;
            ClaimArtifactFr y_diff = ep.y_2 * q_sign - ep.y_1;
            ClaimArtifactFr y_add_identity = y1_plus_y3 * x_diff + (ep.x_3 - ep.x_1) * y_diff;
            evals[11] = y_add_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * (ClaimArtifactFr.wrap(1) - q_is_double);
        }

        // Contribution 10 point doubling, x-coordinate check
        // (x3 + x1 + x1) (4y1*y1) - 9 * x1 * x1 * x1 * x1 = 0
        // N.B. we're using the equivalence x1*x1*x1 === y1*y1 - curve_b to reduce degree by 1
        {
            ClaimArtifactFr x_pow_4 = (y1_sqr + GRUMPKIN_CURVE_B_PARAMETER_NEGATED) * ep.x_1;
            ClaimArtifactFr y1_sqr_mul_4 = y1_sqr + y1_sqr;
            y1_sqr_mul_4 = y1_sqr_mul_4 + y1_sqr_mul_4;
            ClaimArtifactFr x1_pow_4_mul_9 = x_pow_4 * ClaimArtifactFr.wrap(9);

            // NOTE: pushed into memory (stack >:'( )
            ep.x_double_identity = (ep.x_3 + ep.x_1 + ep.x_1) * y1_sqr_mul_4 - x1_pow_4_mul_9;

            ClaimArtifactFr acc = ep.x_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
            evals[10] = evals[10] + acc;
        }

        // Contribution 11 point doubling, y-coordinate check
        // (y1 + y1) (2y1) - (3 * x1 * x1)(x1 - x3) = 0
        {
            ClaimArtifactFr x1_sqr_mul_3 = (ep.x_1 + ep.x_1 + ep.x_1) * ep.x_1;
            ClaimArtifactFr y_double_identity = x1_sqr_mul_3 * (ep.x_1 - ep.x_3) - (ep.y_1 + ep.y_1) * (ep.y_1 + ep.y_3);
            evals[11] = evals[11] + y_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
        }
    }

    // Constants for the auxiliary relation
    ClaimArtifactFr constant LIMB_SIZE = ClaimArtifactFr.wrap(uint256(1) << 68);
    ClaimArtifactFr constant SUBLIMB_SHIFT = ClaimArtifactFr.wrap(uint256(1) << 14);

    // Parameters used within the Auxiliary Relation
    // A struct is used to work around stack too deep. This relation has alot of variables
    struct AuxParams {
        ClaimArtifactFr limb_subproduct;
        ClaimArtifactFr non_native_field_gate_1;
        ClaimArtifactFr non_native_field_gate_2;
        ClaimArtifactFr non_native_field_gate_3;
        ClaimArtifactFr limb_accumulator_1;
        ClaimArtifactFr limb_accumulator_2;
        ClaimArtifactFr memory_record_check;
        ClaimArtifactFr partial_record_check;
        ClaimArtifactFr next_gate_access_type;
        ClaimArtifactFr record_delta;
        ClaimArtifactFr index_delta;
        ClaimArtifactFr adjacent_values_match_if_adjacent_indices_match;
        ClaimArtifactFr adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation;
        ClaimArtifactFr access_check;
        ClaimArtifactFr next_gate_access_type_is_boolean;
        ClaimArtifactFr ROM_consistency_check_identity;
        ClaimArtifactFr RAM_consistency_check_identity;
        ClaimArtifactFr timestamp_delta;
        ClaimArtifactFr RAM_timestamp_check_identity;
        ClaimArtifactFr memory_identity;
        ClaimArtifactFr index_is_monotonically_increasing;
        ClaimArtifactFr auxiliary_identity;
    }

    function accumulateAuxillaryRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactHonk.RelationParameters memory rp,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
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

        ClaimArtifactFr non_native_field_identity =
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

        ClaimArtifactFr limb_accumulator_identity = ap.limb_accumulator_1 + ap.limb_accumulator_2;
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

        ap.adjacent_values_match_if_adjacent_indices_match = (ap.index_delta * MINUS_ONE + ClaimArtifactFr.wrap(1)) * ap.record_delta; // deg 2

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
        ClaimArtifactFr access_type = (wire(p, WIRE.W_4) - ap.partial_record_check); // will be 0 or 1 for honest Prover; deg 1 or 4
        ap.access_check = access_type * access_type - access_type; // check value is 0 or 1; deg 2 or 8

        ap.next_gate_access_type = wire(p, WIRE.W_O_SHIFT) * rp.etaThree;
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_R_SHIFT) * rp.etaTwo);
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_L_SHIFT) * rp.eta);
        ap.next_gate_access_type = wire(p, WIRE.W_4_SHIFT) - ap.next_gate_access_type;

        ClaimArtifactFr value_delta = wire(p, WIRE.W_O_SHIFT) - wire(p, WIRE.W_O);
        ap.adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation = (
            ap.index_delta * MINUS_ONE + ClaimArtifactFr.wrap(1)
        ) * value_delta * (ap.next_gate_access_type * MINUS_ONE + ClaimArtifactFr.wrap(1)); // deg 3 or 6

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
            (ap.index_delta * MINUS_ONE + ClaimArtifactFr.wrap(1)) * ap.timestamp_delta - wire(p, WIRE.W_O); // deg 3

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
        ClaimArtifactFr s1;
        ClaimArtifactFr s2;
        ClaimArtifactFr s3;
        ClaimArtifactFr s4;
        ClaimArtifactFr u1;
        ClaimArtifactFr u2;
        ClaimArtifactFr u3;
        ClaimArtifactFr u4;
        ClaimArtifactFr t0;
        ClaimArtifactFr t1;
        ClaimArtifactFr t2;
        ClaimArtifactFr t3;
        ClaimArtifactFr v1;
        ClaimArtifactFr v2;
        ClaimArtifactFr v3;
        ClaimArtifactFr v4;
        ClaimArtifactFr q_pos_by_scaling;
    }

    function accumulatePoseidonExternalRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
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
        ClaimArtifactFr u1;
        ClaimArtifactFr u2;
        ClaimArtifactFr u3;
        ClaimArtifactFr u4;
        ClaimArtifactFr u_sum;
        ClaimArtifactFr v1;
        ClaimArtifactFr v2;
        ClaimArtifactFr v3;
        ClaimArtifactFr v4;
        ClaimArtifactFr s1;
        ClaimArtifactFr q_pos_by_scaling;
    }

    function accumulatePoseidonInternalRelation(
        ClaimArtifactFr[NUMBER_OF_ENTITIES] memory p,
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evals,
        ClaimArtifactFr domainSep
    ) internal pure {
        PoseidonInternalParams memory ip;

        ClaimArtifactFr[4] memory INTERNAL_MATRIX_DIAGONAL = [
            ClaimArtifactFrLib.from(0x10dc6e9c006ea38b04b1e03b4bd9490c0d03f98929ca1d7fb56821fd19d3b6e7),
            ClaimArtifactFrLib.from(0x0c28145b6a44df3e0149b3d0a30b3bb599df9756d4dd9b84a86b38cfb45a740b),
            ClaimArtifactFrLib.from(0x00544b8338791518b2c7645a50392798b21f75bb60e3596170067d00141cac15),
            ClaimArtifactFrLib.from(0x222c01175718386f2e2e82eb122789e352e105a3b8fa852613bc534433ee428b)
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
        ClaimArtifactFr[NUMBER_OF_SUBRELATIONS] memory evaluations,
        ClaimArtifactFr[NUMBER_OF_ALPHAS] memory subrelationChallenges
    ) internal pure returns (ClaimArtifactFr accumulator) {
        accumulator = accumulator + evaluations[0];

        for (uint256 i = 1; i < NUMBER_OF_SUBRELATIONS; ++i) {
            accumulator = accumulator + evaluations[i] * subrelationChallenges[i - 1];
        }
    }
}

struct ShpleminiIntermediates {
    ClaimArtifactFr unshiftedScalar;
    ClaimArtifactFr shiftedScalar;
    // Scalar to be multiplied by [1]₁
    ClaimArtifactFr constantTermAccumulator;
    // Accumulator for powers of rho
    ClaimArtifactFr batchingChallenge;
    // Linear combination of multilinear (sumcheck) evaluations and powers of rho
    ClaimArtifactFr batchedEvaluation;
    // 1/(z - r^{2^i}) for i = 0, ..., logSize, dynamically updated
    ClaimArtifactFr posInvertedDenominator;
    // 1/(z + r^{2^i}) for i = 0, ..., logSize, dynamically updated
    ClaimArtifactFr negInvertedDenominator;
    // v^{2i} * 1/(z - r^{2^i})
    ClaimArtifactFr scalingFactorPos;
    // v^{2i+1} * 1/(z + r^{2^i})
    ClaimArtifactFr scalingFactorNeg;
    // // Fold_i(r^{2^i}) reconstructed by Verifier
    // ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] foldPosEvaluations;
}

library CommitmentSchemeLib {
    using ClaimArtifactFrLib for ClaimArtifactFr;

    function computeSquares(ClaimArtifactFr r) internal pure returns (ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory squares) {
        squares[0] = r;
        for (uint256 i = 1; i < CONST_PROOF_SIZE_LOG_N; ++i) {
            squares[i] = squares[i - 1].sqr();
        }
    }

    // Compute the evaluations  A_l(r^{2^l}) for l = 0, ..., m-1
    function computeFoldPosEvaluations(
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory sumcheckUChallenges,
        ClaimArtifactFr batchedEvalAccumulator,
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory geminiEvaluations,
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory geminiEvalChallengePowers,
        uint256 logSize
    ) internal view returns (ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory foldPosEvaluations) {
        for (uint256 i = CONST_PROOF_SIZE_LOG_N; i > 0; --i) {
            ClaimArtifactFr challengePower = geminiEvalChallengePowers[i - 1];
            ClaimArtifactFr u = sumcheckUChallenges[i - 1];

            ClaimArtifactFr batchedEvalRoundAcc = (
                (challengePower * batchedEvalAccumulator * ClaimArtifactFr.wrap(2))
                    - geminiEvaluations[i - 1] * (challengePower * (ClaimArtifactFr.wrap(1) - u) - u)
            );
            // Divide by the denominator
            batchedEvalRoundAcc = batchedEvalRoundAcc * (challengePower * (ClaimArtifactFr.wrap(1) - u) + u).invert();

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


abstract contract ClaimArtifactBaseHonkVerifier is IVerifier {
    using ClaimArtifactFrLib for ClaimArtifactFr;

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

    function loadVerificationKey() internal pure virtual returns (ClaimArtifactHonk.VerificationKey memory);

    function verify(bytes calldata proof, bytes32[] calldata publicInputs) public view override returns (bool) {
         // Check the received proof is the expected size where each field element is 32 bytes
        if (proof.length != PROOF_SIZE * 32) {
            revert ProofLengthWrong();
        }

        ClaimArtifactHonk.VerificationKey memory vk = loadVerificationKey();
        ClaimArtifactHonk.Proof memory p = TranscriptLib.loadProof(proof);

        if (publicInputs.length != vk.publicInputsSize) {
            revert PublicInputsLengthWrong();
        }

        // Generate the fiat shamir challenges for the whole protocol
        // TODO(https://github.com/AztecProtocol/barretenberg/issues/1281): Add pubInputsOffset to VK or remove entirely.
        Transcript memory t = TranscriptLib.generateTranscript(p, publicInputs, vk.circuitSize, vk.publicInputsSize, /*pubInputsOffset=*/1);

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

    function computePublicInputDelta(bytes32[] memory publicInputs, ClaimArtifactFr beta, ClaimArtifactFr gamma, uint256 offset)
        internal
        view
        returns (ClaimArtifactFr publicInputDelta)
    {
        ClaimArtifactFr numerator = ClaimArtifactFr.wrap(1);
        ClaimArtifactFr denominator = ClaimArtifactFr.wrap(1);

        ClaimArtifactFr numeratorAcc = gamma + (beta * ClaimArtifactFrLib.from(n + offset));
        ClaimArtifactFr denominatorAcc = gamma - (beta * ClaimArtifactFrLib.from(offset + 1));

        {
            for (uint256 i = 0; i < numPublicInputs; i++) {
                ClaimArtifactFr pubInput = ClaimArtifactFrLib.fromBytes32(publicInputs[i]);

                numerator = numerator * (numeratorAcc + pubInput);
                denominator = denominator * (denominatorAcc + pubInput);

                numeratorAcc = numeratorAcc + beta;
                denominatorAcc = denominatorAcc - beta;
            }
        }

        // ClaimArtifactFr delta = numerator / denominator; // TOOO: batch invert later?
        publicInputDelta = ClaimArtifactFrLib.div(numerator, denominator);
    }

    function verifySumcheck(ClaimArtifactHonk.Proof memory proof, Transcript memory tp) internal view returns (bool verified) {
        ClaimArtifactFr roundTarget;
        ClaimArtifactFr powPartialEvaluation = ClaimArtifactFr.wrap(1);

        // We perform sumcheck reductions over log n rounds ( the multivariate degree )
        for (uint256 round; round < logN; ++round) {
            ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate = proof.sumcheckUnivariates[round];
            bool valid = checkSum(roundUnivariate, roundTarget);
            if (!valid) revert SumcheckFailed();

            ClaimArtifactFr roundChallenge = tp.sumCheckUChallenges[round];

            // Update the round target for the next rounf
            roundTarget = computeNextTargetSum(roundUnivariate, roundChallenge);
            powPartialEvaluation = partiallyEvaluatePOW(tp.gateChallenges[round], powPartialEvaluation, roundChallenge);
        }

        // Last round
        ClaimArtifactFr grandHonkRelationSum =
            RelationsLib.accumulateRelationEvaluations(proof.sumcheckEvaluations, tp.relationParameters, tp.alphas, powPartialEvaluation);
        verified = (grandHonkRelationSum == roundTarget);
    }

    function checkSum(ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate, ClaimArtifactFr roundTarget)
        internal
        pure
        returns (bool checked)
    {
        ClaimArtifactFr totalSum = roundUnivariate[0] + roundUnivariate[1];
        checked = totalSum == roundTarget;
    }

    // Return the new target sum for the next sumcheck round
    function computeNextTargetSum(ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariates, ClaimArtifactFr roundChallenge)
        internal
        view
        returns (ClaimArtifactFr targetSum)
    {
        // TODO: inline
        ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH] memory BARYCENTRIC_LAGRANGE_DENOMINATORS = [
            ClaimArtifactFr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffec51),
            ClaimArtifactFr.wrap(0x00000000000000000000000000000000000000000000000000000000000002d0),
            ClaimArtifactFr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff11),
            ClaimArtifactFr.wrap(0x0000000000000000000000000000000000000000000000000000000000000090),
            ClaimArtifactFr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff71),
            ClaimArtifactFr.wrap(0x00000000000000000000000000000000000000000000000000000000000000f0),
            ClaimArtifactFr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffd31),
            ClaimArtifactFr.wrap(0x00000000000000000000000000000000000000000000000000000000000013b0)
        ];

        // To compute the next target sum, we evaluate the given univariate at a point u (challenge).

        // Performing Barycentric evaluations
        // Compute B(x)
        ClaimArtifactFr numeratorValue = ClaimArtifactFr.wrap(1);
        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            numeratorValue = numeratorValue * (roundChallenge - ClaimArtifactFr.wrap(i));
        }

        // Calculate domain size N of inverses
        ClaimArtifactFr[BATCHED_RELATION_PARTIAL_LENGTH] memory denominatorInverses;
        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            ClaimArtifactFr inv = BARYCENTRIC_LAGRANGE_DENOMINATORS[i];
            inv = inv * (roundChallenge - ClaimArtifactFr.wrap(i));
            inv = ClaimArtifactFrLib.invert(inv);
            denominatorInverses[i] = inv;
        }

        for (uint256 i = 0; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            ClaimArtifactFr term = roundUnivariates[i];
            term = term * denominatorInverses[i];
            targetSum = targetSum + term;
        }

        // Scale the sum by the value of B(x)
        targetSum = targetSum * numeratorValue;
    }

    // Univariate evaluation of the monomial ((1-X_l) + X_l.B_l) at the challenge point X_l=u_l
    function partiallyEvaluatePOW(ClaimArtifactFr gateChallenge, ClaimArtifactFr currentEvaluation, ClaimArtifactFr roundChallenge)
        internal
        pure
        returns (ClaimArtifactFr newEvaluation)
    {
        ClaimArtifactFr univariateEval = ClaimArtifactFr.wrap(1) + (roundChallenge * (gateChallenge - ClaimArtifactFr.wrap(1)));
        newEvaluation = currentEvaluation * univariateEval;
    }

    function verifyShplemini(ClaimArtifactHonk.Proof memory proof, ClaimArtifactHonk.VerificationKey memory vk, Transcript memory tp)
        internal
        view
        returns (bool verified)
    {
        ShpleminiIntermediates memory mem; // stack

        // - Compute vector (r, r², ... , r²⁽ⁿ⁻¹⁾), where n = log_circuit_size
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory powers_of_evaluation_challenge = CommitmentSchemeLib.computeSquares(tp.geminiR);

        // Arrays hold values that will be linearly combined for the gemini and shplonk batch openings
        ClaimArtifactFr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars;
        ClaimArtifactHonk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory commitments;

        mem.posInvertedDenominator = (tp.shplonkZ - powers_of_evaluation_challenge[0]).invert();
        mem.negInvertedDenominator = (tp.shplonkZ + powers_of_evaluation_challenge[0]).invert();

        mem.unshiftedScalar = mem.posInvertedDenominator + (tp.shplonkNu * mem.negInvertedDenominator);
        mem.shiftedScalar =
            tp.geminiR.invert() * (mem.posInvertedDenominator - (tp.shplonkNu * mem.negInvertedDenominator));

        scalars[0] = ClaimArtifactFr.wrap(1);
        commitments[0] = convertProofPoint(proof.shplonkQ);

        mem.batchingChallenge = ClaimArtifactFr.wrap(1);
        mem.batchedEvaluation = ClaimArtifactFr.wrap(0);

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
        ClaimArtifactFr[CONST_PROOF_SIZE_LOG_N] memory foldPosEvaluations = CommitmentSchemeLib.computeFoldPosEvaluations(
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
                ClaimArtifactFr accumContribution = mem.scalingFactorNeg * proof.geminiAEvaluations[i + 1];
                accumContribution = accumContribution + mem.scalingFactorPos * foldPosEvaluations[i + 1];
                mem.constantTermAccumulator = mem.constantTermAccumulator + accumContribution;
                // Update the running power of v
                mem.batchingChallenge = mem.batchingChallenge * tp.shplonkNu * tp.shplonkNu;
            }

            commitments[NUMBER_OF_ENTITIES + 1 + i] = convertProofPoint(proof.geminiFoldComms[i]);
        }

        // Finalise the batch opening claim
        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = ClaimArtifactHonk.G1Point({x: 1, y: 2});
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = mem.constantTermAccumulator;

        ClaimArtifactHonk.G1Point memory quotient_commitment = convertProofPoint(proof.kzgQuotient);

        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = quotient_commitment;
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = tp.shplonkZ; // evaluation challenge

        ClaimArtifactHonk.G1Point memory P_0 = batchMul(commitments, scalars);
        ClaimArtifactHonk.G1Point memory P_1 = negateInplace(quotient_commitment);

        return pairing(P_0, P_1);
    }

    // This implementation is the same as above with different constants
    function batchMul(
        ClaimArtifactHonk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory base,
        ClaimArtifactFr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars
    ) internal view returns (ClaimArtifactHonk.G1Point memory result) {
        uint256 limit = NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2;
        assembly ("memory-safe") {
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

contract ClaimArtifactHonkVerifier is ClaimArtifactBaseHonkVerifier(N, LOG_N, NUMBER_OF_PUBLIC_INPUTS) {
     function loadVerificationKey() internal pure override returns (ClaimArtifactHonk.VerificationKey memory) {
       return ClaimArtifactVerificationKey.loadVerificationKey();
    }
}
