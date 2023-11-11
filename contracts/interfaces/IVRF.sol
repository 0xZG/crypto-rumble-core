// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IVRF {
    struct VR {
        address applicationAddress;
        bytes32 messageHash;
        bytes signature;
        uint8 v;
        bytes32 expectedRandom;
    }

    function register(bytes calldata publicKey) external returns (bool result);

    function verify(
        address applicationAddress,
        bytes32 messageHash,
        bytes calldata signature,
        uint8 v,
        bytes32 expectedRandom
    ) external returns (bool result);
}
