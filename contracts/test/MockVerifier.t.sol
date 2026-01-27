// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockVerifier, RejectVerifier} from "../src/MockVerifier.sol";
import {IShadowVerifier} from "../src/interfaces/IShadowVerifier.sol";

contract MockVerifierTest is Test {
    MockVerifier public mockVerifier;
    RejectVerifier public rejectVerifier;

    function setUp() public {
        mockVerifier = new MockVerifier();
        rejectVerifier = new RejectVerifier();
    }

    // =========================================================================
    //                      MockVerifier TESTS
    // =========================================================================

    function test_mockVerifier_alwaysTrue() public view {
        bytes memory proof = hex"deadbeef";
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = bytes32(uint256(42));

        assertTrue(mockVerifier.verify(proof, inputs));
    }

    function test_mockVerifier_emptyInputs() public view {
        bytes memory proof = hex"";
        bytes32[] memory inputs = new bytes32[](0);

        assertTrue(mockVerifier.verify(proof, inputs));
    }

    function test_mockVerifier_largeInputs() public view {
        bytes memory proof = new bytes(1024);
        bytes32[] memory inputs = new bytes32[](10);
        for (uint i = 0; i < 10; i++) {
            inputs[i] = bytes32(uint256(i));
        }

        assertTrue(mockVerifier.verify(proof, inputs));
    }

    function testFuzz_mockVerifier_anyInput(bytes calldata proof, uint256 inputVal) public view {
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = bytes32(inputVal);
        assertTrue(mockVerifier.verify(proof, inputs));
    }

    function test_mockVerifier_implementsInterface() public view {
        // Verify it conforms to IShadowVerifier
        IShadowVerifier verifier = IShadowVerifier(address(mockVerifier));
        bytes32[] memory inputs = new bytes32[](0);
        assertTrue(verifier.verify(hex"", inputs));
    }

    // =========================================================================
    //                     RejectVerifier TESTS
    // =========================================================================

    function test_rejectVerifier_alwaysFalse() public view {
        bytes memory proof = hex"deadbeef";
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = bytes32(uint256(42));

        assertFalse(rejectVerifier.verify(proof, inputs));
    }

    function test_rejectVerifier_emptyInputs() public view {
        bytes memory proof = hex"";
        bytes32[] memory inputs = new bytes32[](0);

        assertFalse(rejectVerifier.verify(proof, inputs));
    }

    function testFuzz_rejectVerifier_anyInput(bytes calldata proof, uint256 inputVal) public view {
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = bytes32(inputVal);
        assertFalse(rejectVerifier.verify(proof, inputs));
    }

    function test_rejectVerifier_implementsInterface() public view {
        IShadowVerifier verifier = IShadowVerifier(address(rejectVerifier));
        bytes32[] memory inputs = new bytes32[](0);
        assertFalse(verifier.verify(hex"", inputs));
    }
}
