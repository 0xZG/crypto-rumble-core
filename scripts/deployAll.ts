require("dotenv").config();

import { deployCryptoRumble, deployGameHub } from "./utils";

const {
    VRF_VERIFIER_ADDRESS
} = process.env;

async function main() {
    const cryptoRumble = await deployCryptoRumble();
    const hub = await deployGameHub();

    await cryptoRumble.setHubRole(await hub.getAddress());
    await cryptoRumble.setVRF(VRF_VERIFIER_ADDRESS as string);

    await hub.registerGame("CryptoRumble", await cryptoRumble.getAddress());

    console.log("CryptoRumble deployed to:", await cryptoRumble.getAddress());
    console.log("GameHub deployed to:", await hub.getAddress());
}

main().catch(e => {
    console.log(e);
})