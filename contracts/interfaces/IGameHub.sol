// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IVRF.sol";

interface IGameHub {
    struct GameScore {
        address player;
        uint256 score;
    }

    struct VerifyData {
        uint[2] _pA;
        uint[2][2] _pB;
        uint[2] _pC;
        uint[12] _pubSignals;
    }

    function registerGame(string calldata name, address game) external;

    function newGame(
        string calldata name,
        uint256[] calldata params,
        IVRF.VR calldata vr
    ) external payable;

    function uploadScores(
        string calldata name,
        VerifyData[] calldata data,
        uint256[] calldata params
    ) external;

    function top10(
        string calldata name
    ) external view returns (GameScore[10] memory);

    function maxScore(
        string calldata name,
        address player
    ) external view returns (uint256);
}

interface IGame {
    function newGame(
        uint256[] calldata params,
        address player,
        IVRF.VR calldata vr
    ) external payable;

    function uploadScores(
        IGameHub.VerifyData[] calldata data,
        uint256[] calldata params,
        address player
    ) external returns (uint256);

    function scores(
        uint256 gameId
    ) external view returns (IGameHub.GameScore memory);
}
