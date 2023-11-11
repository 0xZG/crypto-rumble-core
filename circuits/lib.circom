pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";

template OR2() {
    signal input a;
    signal input b;
    signal output out;

    out <== a + b - a*b;
}

template OR3() {
    signal input a;
    signal input b;
    signal input c;
    signal output out;

    signal ab <-- a*b;
    signal bc <-- b*c;
    signal ca <-- c*a;

    out <== a + b + c - ab - bc - ca + ab*c;
}

// This circuit returns the sum of the inputs.
// n must be greater than 0.
template CalculateTotal(n) {
    signal input nums[n];
    signal output sum;

    signal sums[n];
    sums[0] <== nums[0];

    for (var i=1; i < n; i++) {
        sums[i] <== sums[i - 1] + nums[i];
    }

    sum <== sums[n - 1];
}

template LogBoard() {
    signal input board[8][8];

    log("[");
    for (var i = 0; i < 8; i++) {
        log(board[i][0], ", ", board[i][1], ", ", board[i][2], ", ", board[i][3], ", ", board[i][4], ", ", board[i][5], ", ", board[i][6], ", ", board[i][7]);
    }
    log("]");
}

template IsEliminateBy9() {
    signal input around[8];
    signal output out;

    component sum = CalculateTotal(8);
    sum.nums <== around;

    component gt = GreaterThan(4);
    gt.in <== [sum.sum, 0];
    out <== gt.out;
}

template NewTile() {
    signal input seed;
    signal output out;
    signal output seedOut;

    signal newTile <-- seed % 5 + 1;
    signal quotient <-- seed \ 5;

    quotient * 5 + newTile - 1 === seed;

    component lt = LessThan(3);
    lt.in <== [newTile, 6];
    lt.out === 1;

    // note that '/' operator in circom is multiplication inverse modulo of p
    seedOut <== seed / 5;
    out <== newTile;
}

template IsNotZero() {
    signal input in;
    signal output out;

    component izr = IsZero();
    izr.in <== in;

    out <== 1 + izr.out - 2*izr.out;
}