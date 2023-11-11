#!/bin/bash

CIRCUIT=$CIRCUIT_NAME
CONTRACT_NAME=$CONTRACT_NAME

mkdir -p zk/zkey
circom circuits/$CIRCUIT.circom --r1cs --wasm --output zk

yarn snarkjs groth16 setup zk/$CIRCUIT.r1cs $PTAU_LOC zk/zkey/$CIRCUIT.final.zkey
yarn snarkjs zkey new zk/$CIRCUIT.r1cs $PTAU_LOC zk/zkey/$CIRCUIT.00.zkey

# # Ceremony just like before but for zkey this time
yarn snarkjs zkey contribute zk/zkey/$CIRCUIT.00.zkey zk/zkey/$CIRCUIT.01.zkey \
    --name="First crypto rumble contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
yarn snarkjs zkey contribute zk/zkey/$CIRCUIT.01.zkey zk/zkey/$CIRCUIT.02.zkey \
    --name="Second crypto rumble contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
yarn snarkjs zkey contribute zk/zkey/$CIRCUIT.02.zkey zk/zkey/$CIRCUIT.03.zkey \
    --name="Third crypto rumble contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"

# #  Verify zkey
yarn snarkjs zkey verify zk/$CIRCUIT.r1cs $PTAU_LOC zk/zkey/$CIRCUIT.03.zkey

# # Apply random beacon as before
yarn snarkjs zkey beacon zk/zkey/$CIRCUIT.03.zkey zk/zkey/$CIRCUIT.final.zkey \
    0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="crypto rumble FinalBeacon phase2"

# # Optional: verify final zkey
yarn snarkjs zkey verify zk/$CIRCUIT.r1cs $PTAU_LOC zk/zkey/$CIRCUIT.final.zkey

# # Export verification key
yarn snarkjs zkey export verificationkey zk/zkey/$CIRCUIT.final.zkey zk/$CIRCUIT.verification.json

# Export board verifier with updated name and solidity version
yarn snarkjs zkey export solidityverifier zk/zkey/$CIRCUIT.final.zkey contracts/$CONTRACT_NAME.sol
sed -i 's/contract Groth16Verifier/contract '$CONTRACT_NAME'/g' contracts/$CONTRACT_NAME.sol