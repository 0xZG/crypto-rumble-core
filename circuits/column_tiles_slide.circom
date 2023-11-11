pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./lib.circom";

template ColumnTilesSlide() {
    signal input column[8];
    signal input seed;

    signal output outColumn[8];
    signal output outSeed;

    component slide1 = SlideN(1);
    slide1.tiles <== [column[7]];
    slide1.seed <== seed;

    component slide2 = SlideN(2);
    slide2.tiles <== [column[6], slide1.slidTiles[0]];
    slide2.seed <== slide1.outSeed;

    component slide3 = SlideN(3);
    slide3.tiles <== [column[5], slide2.slidTiles[0], slide2.slidTiles[1]];
    slide3.seed <== slide2.outSeed;

    component slide4 = SlideN(4);
    slide4.tiles <== [column[4], slide3.slidTiles[0], slide3.slidTiles[1], slide3.slidTiles[2]];
    slide4.seed <== slide3.outSeed;

    component slide5 = SlideN(5);
    slide5.tiles <== [column[3], slide4.slidTiles[0], slide4.slidTiles[1], slide4.slidTiles[2], slide4.slidTiles[3]];
    slide5.seed <== slide4.outSeed;

    component slide6 = SlideN(6);
    slide6.tiles <== [column[2], slide5.slidTiles[0], slide5.slidTiles[1], slide5.slidTiles[2], slide5.slidTiles[3], slide5.slidTiles[4]];
    slide6.seed <== slide5.outSeed;

    component slide7 = SlideN(7);
    slide7.tiles <== [column[1], slide6.slidTiles[0], slide6.slidTiles[1], slide6.slidTiles[2], slide6.slidTiles[3], slide6.slidTiles[4], slide6.slidTiles[5]];
    slide7.seed <== slide6.outSeed;

    component slide8 = SlideN(8);
    slide8.tiles <== [column[0], slide7.slidTiles[0], slide7.slidTiles[1], slide7.slidTiles[2], slide7.slidTiles[3], slide7.slidTiles[4], slide7.slidTiles[5], slide7.slidTiles[6]];
    slide8.seed <== slide7.outSeed;

    outColumn <== slide8.slidTiles;
    outSeed <== slide8.outSeed;
}

template SlideN(N) {
    signal input tiles[N];
    signal input seed;

    signal output slidTiles[N];
    signal output outSeed;

    component isz = IsZero();
    isz.in <== tiles[0];

    for (var i=0; i < N-1; i++) {
        slidTiles[i] <== (tiles[i+1]-tiles[i])*isz.out + tiles[i];
    }

    component nc = NewTile();
    nc.seed <== seed;

    slidTiles[N-1] <== (nc.out-tiles[N-1])*isz.out + tiles[N-1];
    outSeed <== (nc.seedOut-seed)*isz.out + seed;
}

