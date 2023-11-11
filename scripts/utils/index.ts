import { ethers, upgrades } from "hardhat";
import { GameHub, CryptoRumble } from "../../typechain-types";

export async function deployVerifier() {
    const verifier = await ethers.getContractFactory("CandyCrushDemoVerifier");
    const verifierContract = await verifier.deploy();
    await verifierContract.waitForDeployment();
    return verifierContract;
}

export async function deployCryptoRumble() {
    const verifier = await deployVerifier();

    const CryptoRumble = await ethers.getContractFactory("CryptoRumble");
    const cryptoRumble = await upgrades.deployProxy(CryptoRumble, [await verifier.getAddress()], { kind: "uups" }) as unknown as CryptoRumble;
    await cryptoRumble.waitForDeployment();
    return cryptoRumble;
}
export async function deployGameHub() {
    const Hub = await ethers.getContractFactory("GameHub");
    const hubContract = await upgrades.deployProxy(Hub, [], { kind: "uups" }) as unknown as GameHub;
    await hubContract.waitForDeployment();

    return hubContract;
}