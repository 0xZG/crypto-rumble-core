// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IVerifier.sol";
import "./interfaces/IGameHub.sol";
import "./interfaces/IVRF.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// import "hardhat/console.sol";

contract GameHub is AccessControlUpgradeable, UUPSUpgradeable, IGameHub {
    uint256 public version;

    mapping(bytes32 => IGame) public games;
    mapping(bytes32 => GameScore[10]) public gamesTop10;
    mapping(bytes32 => mapping(address => uint256)) public maxScores;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        version = 1;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        version++;
    }

    function registerGame(
        string calldata name,
        address game
    ) external override {
        bytes32 mod = keccak256(bytes(name));
        require(
            address(games[mod]) == address(0),
            "GameHub: already registered"
        );
        games[mod] = IGame(game);
    }

    function delistGame(
        string calldata name
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 mod = keccak256(bytes(name));
        require(address(games[mod]) != address(0), "GameHub: not registered");
        delete games[mod];
    }

    function newGame(
        string calldata name,
        uint256[] calldata params,
        IVRF.VR calldata vr
    ) external payable {
        bytes32 mod = keccak256(bytes(name));
        require(address(games[mod]) != address(0), "GameHub: unregistered");

        IGame gameContract = games[mod];

        require(msg.sender == tx.origin, "GameHub: no contract allowed");

        gameContract.newGame{value: msg.value}(params, msg.sender, vr);
    }

    function uploadScores(
        string calldata game,
        VerifyData[] calldata data,
        uint256[] calldata params
    ) external override {
        bytes32 mod = keccak256(bytes(game));
        require(address(games[mod]) != address(0), "GameHub: unregistered");

        IGame gameContract = games[mod];

        require(msg.sender == tx.origin, "GameHub: no contract allowed");

        uint256 gid = gameContract.uploadScores(data, params, msg.sender);
        GameScore memory s = gameContract.scores(gid);
        if (s.score > maxScores[mod][s.player]) {
            maxScores[mod][s.player] = s.score;
            addTop10(mod, s);
        }
    }

    function addTop10(bytes32 mod, GameScore memory s) internal {
        GameScore[10] memory scores = gamesTop10[mod];

        uint256 minIdx = 0;
        uint256 myself = scores.length;

        for (uint256 i = 0; i < scores.length; i++) {
            if (s.player == scores[i].player) {
                myself = i;
                break;
            }

            if (scores[minIdx].score > scores[i].score) {
                minIdx = i;
            }
        }

        if (myself != scores.length) {
            gamesTop10[mod][myself] = s;
            return;
        }

        if (s.score > scores[minIdx].score) {
            gamesTop10[mod][minIdx] = s;
        }
    }

    function top10(
        string calldata name
    ) external view returns (GameScore[10] memory) {
        bytes32 mod = keccak256(bytes(name));
        return gamesTop10[mod];
    }

    function maxScore(
        string calldata name,
        address player
    ) external view returns (uint256) {
        bytes32 mod = keccak256(bytes(name));
        return maxScores[mod][player];
    }
}
