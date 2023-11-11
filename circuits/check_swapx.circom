pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "./lib.circom";

template CheckSwapX() {
    signal input oldBoard[8][8];
    signal input newBoard[8][8];
    signal input start[2];
    signal input noSwap;

    signal output swapped;

    var diffBoard[8][8];
    var sumBoard[8][8];
    var prodBoard[8][8];

    signal d[64];
    component calculateTotal[8];

    component eq[64];
    component and[65];

    and[0] = AND();
    and[0].a <== 1;
    and[0].b <== 1;

    component xEq[8];
    component yEq[8];
    component oldEq10[64];
    component newEq10[64];

    for (var i = 0; i < 8; i++) {
        xEq[i] = IsEqual();
        yEq[i] = IsEqual();

        xEq[i].in <== [i, start[0]];
        yEq[i].in <== [i, start[1]];
    }

    signal xy[64];

    for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
            eq[8*y+x] = IsEqual();
            eq[8*y+x].in <== [oldBoard[x][y], newBoard[x][y]];

            xy[8*y+x] <== xEq[x].out * yEq[y].out;

            oldEq10[8*y+x] = IsEqual();
            oldEq10[8*y+x].in <== [oldBoard[x][y], 6];
            oldEq10[8*y+x].out * xy[8*y+x] === 0;

            newEq10[8*y+x] = IsEqual();
            newEq10[8*y+x].in <== [newBoard[x][y], 6];
            newEq10[8*y+x].out * xy[8*y+x] === 0;

            and[8*y+x+1] = AND();
            and[8*y+x+1].a <== eq[8*y+x].out;
            and[8*y+x+1].b <== and[8*y+x].out;

            diffBoard[x][y] = newBoard[x][y]-oldBoard[x][y];
            sumBoard[x][y] = newBoard[x][y]+oldBoard[x][y];
            prodBoard[x][y] = sumBoard[x][y]*diffBoard[x][y];

            diffBoard[x][y] * (start[1]-y) === 0;
            d[8*y+x] <== (start[0]-x) * (start[0]-x+1);
            diffBoard[x][y] * d[8*y+x] === 0;
        }
        calculateTotal[y] = CalculateTotal(8);
        calculateTotal[y].nums <== [prodBoard[0][y], prodBoard[1][y], prodBoard[2][y], prodBoard[3][y],
            prodBoard[4][y], prodBoard[5][y], prodBoard[6][y], prodBoard[7][y]];
        calculateTotal[y].sum === 0;
    }

    // if no swap, then old board should equal to new board
    noSwap === and[64].out;

    component n = NOT();
    n.in <== and[64].out;
    swapped <== n.out;
}
