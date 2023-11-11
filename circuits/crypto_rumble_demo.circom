pragma circom 2.0.6;

include "../node_modules/circomlib/circuits/comparators.circom";

include "match.circom";
include "check_swapx.circom";

template BoardEqual() {
    signal input b1[8][8];
    signal input b2[8][8];

    for (var x = 0; x < 8; x++) {
        for (var y = 0; y < 8; y++) {
            b1[x][y] === b2[x][y];
        }
    }
}

template CryptoRumble(N) {
    signal input fromSeed;
    signal input toSeed;
    signal input fromBoard[8][8];
    signal input toBoard[8][8];
    signal input afterMoveBoard[N][8][8];
    signal input step;
    signal input stepAfter;

    signal input boardPacked[2];
    signal input scorePacked;
    signal input posPacked;
    signal input itemPacked;
    // items and direction and the third elements of move
    // and 1 is y swap, 0 is x swap
    signal input move[N][3];

    signal packedBoard[2][64];
    signal packedScore[5];
    signal packedPos[N];
    signal packedItem[N];

    for (var x = 0; x < 8; x++) {
        for (var y = 0; y < 8; y++) {
            if (x*8+y == 0) {
                packedBoard[0][x*8+y] <== fromBoard[x][y];
                packedBoard[1][x*8+y] <== toBoard[x][y];
            } else {
                packedBoard[0][x*8+y] <== packedBoard[0][x*8+y-1]*8 + fromBoard[x][y];
                packedBoard[1][x*8+y] <== packedBoard[1][x*8+y-1]*8 + toBoard[x][y];
            }
        }
    }

    packedBoard[0][63] === boardPacked[0];
    packedBoard[1][63] === boardPacked[1];

    for (var i = 0; i < N; i++) {
        if (i == 0) {
            packedPos[i] <== move[i][0]*8 + move[i][1];
            packedItem[i] <== move[i][2];
        } else {
            packedPos[i] <== packedPos[i-1]*64 + move[i][0]*8 + move[i][1];
            packedItem[i] <== packedItem[i-1]*256 + move[i][2];
        }
    }

    packedPos[N-1] === posPacked;
    packedItem[N-1] === itemPacked;

    signal intermediateSeed[N+1];
    signal intermediateBoard[N+1][8][8];
    signal intermediateScore[N+1][5];
    signal intermediateStep[N+1];

    signal output scoreOut[5];

    intermediateStep[0] <== step;
    intermediateBoard[0] <== fromBoard;
    intermediateSeed[0] <== fromSeed;
    intermediateScore[0] <== [0, 0, 0, 0, 0];

    component swap[N];
    component matches[N];
    component applyItems[N];
    component isYSwap[N];
    component isNoSwap[N];
    component gt[N];

    for (var z = 0; z < N; z++) {
        var afterMoved[8][8];
        var intermediateBoardMirror[8][8];
        var xMirror;
        var yMirror;

        isYSwap[z] = IsEqual();
        isYSwap[z].in <== [move[z][2], 2];

        isNoSwap[z] = IsZero();
        isNoSwap[z].in <== move[z][2];

        // 0 is no swap, 1 is x swap, 2 is y swap
        gt[z] = GreaterThan(3);
        gt[z].in <== [move[z][2], 2];

        for (var y = 0; y < 8; y++) {
            for (var x = 0; x < 8; x++) {
                afterMoved[x][y] = (afterMoveBoard[z][y][x] - afterMoveBoard[z][x][y])*isYSwap[z].out + afterMoveBoard[z][x][y];
                intermediateBoardMirror[x][y] = (intermediateBoard[z][y][x] - intermediateBoard[z][x][y])*isYSwap[z].out + intermediateBoard[z][x][y];
                xMirror = (move[z][1]-move[z][0])*isYSwap[z].out + move[z][0];
                yMirror = (move[z][0]-move[z][1])*isYSwap[z].out + move[z][1];
            }
        }

        swap[z] = CheckSwapX();
        swap[z].oldBoard <== intermediateBoardMirror;
        swap[z].newBoard <== afterMoved;
        swap[z].noSwap <== isNoSwap[z].out + gt[z].out - gt[z].out*isNoSwap[z].out;
        swap[z].start <== [xMirror, yMirror];

        // item and swap is invalid, only allow one of no-swap, item, valid swap
        swap[z].swapped * gt[z].out === 0;

        matches[z] = Match(8);
        matches[z].board <== afterMoveBoard[z];
        matches[z].seed <== intermediateSeed[z];

        intermediateSeed[z+1] <== matches[z].seedOut;
        intermediateBoard[z+1] <== matches[z].boardOut;
        intermediateStep[z+1] <== intermediateStep[z]+swap[z].swapped;

        for (var i = 0; i < 5; i++) {
            intermediateScore[z+1][i] <== intermediateScore[z][i] + matches[z].scoreOut[i];
        }
    }

    for (var i = 0; i < 5; i++) {
        if (i == 0) {
            packedScore[i] <== intermediateScore[N][i];
        } else {
            packedScore[i] <== packedScore[i-1] * 2048 + intermediateScore[N][i];
        }
    }
    packedScore[4] === scorePacked;

    component be = BoardEqual();
    be.b1 <== intermediateBoard[N];
    be.b2 <== toBoard;

    toSeed === intermediateSeed[N];
    stepAfter === intermediateStep[N];
    scoreOut <== intermediateScore[N];
}

component main { public [boardPacked, scorePacked, step, stepAfter, fromSeed, toSeed]} = CryptoRumble(30);