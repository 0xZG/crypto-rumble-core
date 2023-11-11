// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IVerifier.sol";
import "./interfaces/IVRF.sol";
import "./interfaces/IGameCryptoRumble.sol";
import "./interfaces/IGameHub.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

uint256 constant NONCE_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

contract CryptoRumble is
    IGameCryptoRumble,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant HUB_ROLE = keccak256("HUB_ROLE");

    uint256 maxGameId;
    mapping(address => uint256) public currentGame;
    mapping(uint256 => Game) public games;
    mapping(address => uint256) public maxScores;
    uint256 public maxProofUpload;
    uint256 public playSteps;

    IVerifier public verifier;
    uint256 public version;

    IVRF public ivrf;

    function initialize(IVerifier vrfr) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        verifier = vrfr;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        version = 1;
        maxProofUpload = 2;
        playSteps = 30;
    }

    function setVRF(IVRF vrf) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ivrf = vrf;
    }

    function setHubRole(address hub) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(HUB_ROLE, hub);
    }

    function calculateScore(uint256 score) public pure returns (uint256) {
        uint256 scoreOut;

        for (uint256 i = 0; i < 5; i++) {
            scoreOut += score & 2047;
            score >>= 11;
        }
        return scoreOut;
    }

    function setVerifier(IVerifier vrfr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verifier = vrfr;
    }

    function setMaxProofUpload(
        uint256 max
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxProofUpload = max;
    }

    function setPlaySteps(uint256 steps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        playSteps = steps;
    }

    // params = [reset, packedBoard]
    function newGame(
        uint256[] calldata params,
        address player,
        IVRF.VR calldata vr
    ) external payable override onlyRole(HUB_ROLE) {
        require(params.length == 2, "CryptoRumble: invalid params");
        require(
            currentGame[player] == 0 || params[0] == 1,
            "CryptoRumble: game exists"
        );

        if (currentGame[player] != 0) {
            games[currentGame[player]].timestamp = uint128(block.timestamp);
        }

        uint256 board = params[1];

        // verify nonce here
        if (address(ivrf) != address(0)) {
            require(
                ivrf.verify(
                    vr.applicationAddress,
                    vr.messageHash,
                    vr.signature,
                    vr.v,
                    vr.expectedRandom
                ),
                "CryptoRumble: invalid random"
            );
        }

        Game memory g = Game(
            ++maxGameId,
            player,
            0 /*encodeScores*/,
            0 /*score*/,
            uint256(vr.expectedRandom) % NONCE_MOD /*nonce*/,
            board /*board*/,
            0 /*moves*/,
            0 /*timestamp*/
        );
        currentGame[player] = g.gameId;
        games[g.gameId] = g;

        emit NewGame(player, g.gameId);
    }

    function uploadScores(
        IGameHub.VerifyData[] calldata data,
        uint256[] calldata params,
        address player
    ) external override onlyRole(HUB_ROLE) returns (uint256) {
        require(currentGame[player] != 0, "CrytoRumble: no Game");
        require(
            data.length <= maxProofUpload + 1,
            "CrytoRumble: too many proofs"
        );
        require(params.length == 0, "CryptoRumble: invalid params");

        Game memory g = games[currentGame[player]];

        bool gameOver = false;
        uint256 lastEncodedBoard = g.board;
        for (uint256 i = 0; i < data.length; i++) {
            require(
                verifier.verifyProof(
                    data[i]._pA,
                    data[i]._pB,
                    data[i]._pC,
                    data[i]._pubSignals
                ),
                "CryptoRumble: Invalid proof"
            );

            require(
                data[i]._pubSignals[8] <= playSteps,
                "CryptoRumble: too many steps"
            );

            gameOver = (data[i]._pubSignals[8] == playSteps) || gameOver;

            require(
                lastEncodedBoard == data[i]._pubSignals[9],
                "CryptoRumble: board changed"
            );

            lastEncodedBoard = data[i]._pubSignals[10];

            require(
                g.nonce == data[i]._pubSignals[5],
                "CryptoRumble: nonce changed"
            );
            g.nonce = data[i]._pubSignals[6];
        }

        if (data.length != 0) {
            IGameHub.VerifyData calldata lastData = data[data.length - 1];
            g.board = lastEncodedBoard;
            g.encodeScores = g.encodeScores + lastData._pubSignals[11];
            g.score = g.score + calculateScore(g.encodeScores);
            g.moves = uint128(lastData._pubSignals[8]);
        }

        if (gameOver) {
            currentGame[player] = 0;
            g.timestamp = uint128(block.timestamp);
            emit GameOver(g.gameId, g.score);
        }
        games[g.gameId] = g;
        return g.gameId;
    }

    function scores(
        uint256 gameId
    ) external view override returns (IGameHub.GameScore memory) {
        Game memory g = games[gameId];
        return IGameHub.GameScore(g.player, g.score);
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        version++;
    }
}
