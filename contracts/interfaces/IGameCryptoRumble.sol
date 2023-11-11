// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IGameHub.sol";

interface IGameCryptoRumble is IGame {
    // pubSignals contains placeholders 0~4,
    // fromSeed:5, toSeed:6, step:7, stepAfter:8, packedBoard[2]:9,10, packedScore:11
    struct Game {
        uint256 gameId;
        address player;
        uint256 encodeScores;
        uint256 score;
        uint256 nonce;
        uint256 board;
        uint128 moves;
        uint128 timestamp;
    }

    event GameOver(uint256 gameId, uint256 score);
    event NewGame(address player, uint256 gameId);
    event NewNonce(uint256 gameId, uint256 nonce);
}
