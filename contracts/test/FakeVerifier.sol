// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IVerifier.sol";

contract FakeVerifier is IVerifier {
    function verifyProof(
        uint[2] calldata,
        uint[2][2] calldata,
        uint[2] calldata,
        uint[12] calldata
    ) external pure override returns (bool) {
        return true;
    }
}
