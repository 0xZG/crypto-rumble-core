pragma circom 2.0.6;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "./lib.circom";
include "./column_tiles_slide.circom";

template VerticalMatch(N) {
    signal input board[N][N];

    signal Match3Board[N][N];
    signal output tilesRemovedBoard[N][N];

    signal VerticalMatches[N][N];
    component eq[N*(N-1)];
    component isObstacle[N*N];

    for (var x = 0; x < N; x++) {
        for (var y = 0; y < N-1; y++) {
            eq[(N-1)*x+y] = IsEqual();
            eq[(N-1)*x+y].in[0] <== board[x][y];
            eq[(N-1)*x+y].in[1] <== board[x][y+1];

            isObstacle[N*x+y] = IsEqual();
            isObstacle[N*x+y].in[0] <== board[x][y];
            isObstacle[N*x+y].in[1] <== 6;

            VerticalMatches[x][y] <== eq[(N-1)*x+y].out;
        }

        isObstacle[N*x+N-1] = IsEqual();
        isObstacle[N*x+N-1].in[0] <== board[x][N-1];
        isObstacle[N*x+N-1].in[1] <== 6;
    }

    component and[N*(N-2)];
    for (var x = 0; x < N; x++) {
        for (var y = 0; y < N-2; y++) {
            and[(N-2)*x+y] = AND();
            and[(N-2)*x+y].a <== VerticalMatches[x][y];
            and[(N-2)*x+y].b <== VerticalMatches[x][y+1];
            Match3Board[x][y] <== and[(N-2)*x+y].out;
        }
        for (var y = N-2; y < N; y++) {
            Match3Board[x][y] <== 0;
        }
    }
    component or2[N];
    component or3[N*(N-2)];
    for (var x = 0; x < N; x++) {
        tilesRemovedBoard[x][0] <== Match3Board[x][0];

        or2[x] = OR2();
        or2[x].a <== Match3Board[x][0];
        or2[x].b <== Match3Board[x][1];

        tilesRemovedBoard[x][1] <== or2[x].out;

        for (var y = 2; y < N; y++) {
            or3[(N-2)*x+y-2] = OR3();
            or3[(N-2)*x+y-2].a <== Match3Board[x][y-2];
            or3[(N-2)*x+y-2].b <== Match3Board[x][y-1];
            or3[(N-2)*x+y-2].c <== Match3Board[x][y];

            tilesRemovedBoard[x][y] <== or3[(N-2)*x+y-2].out;
        }
    }
}

template HorizontalMatch(N) {
    signal input board[N][N];

    signal Match3Board[N][N];
    signal output tilesRemovedBoard[N][N];

    signal HorizontalMatches[N][N];
    component eq[N*(N-1)];
    component isObstacle[N*N];

    for (var y = 0; y < N; y++) {
        for (var x = 0; x < N-1; x++) {
            eq[(N-1)*y+x] = IsEqual();
            eq[(N-1)*y+x].in[0] <== board[x][y];
            eq[(N-1)*y+x].in[1] <== board[x+1][y];

            isObstacle[N*x+y] = IsEqual();
            isObstacle[N*x+y].in[0] <== board[x][y];
            isObstacle[N*x+y].in[1] <== 6;

            HorizontalMatches[x][y] <== eq[(N-1)*y+x].out;
        }

        isObstacle[N*(N-1)+y] = IsEqual();
        isObstacle[N*(N-1)+y].in[0] <== board[N-1][y];
        isObstacle[N*(N-1)+y].in[1] <== 6;
    }

    component and[N*(N-2)];
    for (var y = 0; y < N; y++) {
        for (var x = 0; x < N-2; x++) {
            and[(N-2)*y+x] = AND();
            and[(N-2)*y+x].a <== HorizontalMatches[x][y];
            and[(N-2)*y+x].b <== HorizontalMatches[x+1][y];
            Match3Board[x][y] <== and[(N-2)*y+x].out;
        }
        for (var x = N-2; x < N; x++) {
            Match3Board[x][y] <== 0;
        }
    }

    component or2[N];
    component or3[N*(N-2)];
    for (var y = 0; y < N; y++) {
        tilesRemovedBoard[0][y] <== Match3Board[0][y];
 
        or2[y] = OR2();
        or2[y].a <== Match3Board[0][y];
        or2[y].b <== Match3Board[1][y];

        tilesRemovedBoard[1][y] <== or2[y].out;

        for (var x = 2; x < N; x++) {
            or3[(N-2)*y+x-2] = OR3();
            or3[(N-2)*y+x-2].a <== Match3Board[x-2][y];
            or3[(N-2)*y+x-2].b <== Match3Board[x-1][y];
            or3[(N-2)*y+x-2].c <== Match3Board[x][y];

            tilesRemovedBoard[x][y] <== or3[(N-2)*y+x-2].out;
        }
    }
}

template Match(N) {
    signal input board[N][N];
    signal input seed;

    signal output boardOut[N][N];
    signal output seedOut;
    signal output scoreOut[5];

    signal removedBoard[3][N][N];

    component isObstacle[N][N];

    for (var x = 0; x < N; x++) {
        for (var y = 0; y < N; y++) {
            isObstacle[x][y] = IsEqual();
            isObstacle[x][y].in <== [board[x][y], 6];
        }
    }

    component vmatch = VerticalMatch(8);
    vmatch.board <== board;

    removedBoard[0] <== vmatch.tilesRemovedBoard;

    component hmatch = HorizontalMatch(8);
    hmatch.board <== board;

    removedBoard[1] <== hmatch.tilesRemovedBoard;

    component slide[N];
    component or[N][N];
    component isCrypto[5][N*N];
    component mux[N*N];
    component score[5];
    var tempSeed = seed;

    for (var i = 0; i < 5; i++) {
        score[i] = CalculateTotal(N*N);
    }

    for (var x = 0; x < N; x++) {
        slide[x] = ColumnTilesSlide();
        for (var y = 0; y < N; y++) {
            or[x][y] = OR2();
            or[x][y].a <== removedBoard[0][x][y]*(1+isObstacle[x][y].out-2*isObstacle[x][y].out);
            or[x][y].b <== removedBoard[1][x][y]*(1+isObstacle[x][y].out-2*isObstacle[x][y].out);
            removedBoard[2][x][y] <== or[x][y].out;

            for (var i = 0; i < 5; i++) {
                isCrypto[i][N*x+y] = IsEqual();
                isCrypto[i][N*x+y].in <== [i+1, board[x][y]];

                score[i].nums[N*x+y] <== removedBoard[2][x][y]*isCrypto[i][N*x+y].out;
            }

            mux[N*x+y] = Mux1();
            mux[N*x+y].c <== [0, board[x][y]];
            mux[N*x+y].s <== 1 + removedBoard[2][x][y] - 2*removedBoard[2][x][y];

            slide[x].column[y] <== mux[N*x+y].out;
        }
        slide[x].seed <== tempSeed;
        boardOut[x] <== slide[x].outColumn;
        tempSeed = slide[x].outSeed;
    }

    seedOut <== tempSeed;
    for (var i = 0; i < 5; i++) {
        scoreOut[i] <== score[i].sum;
    }
}