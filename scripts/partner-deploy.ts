import {parseEther} from "ethers/lib/utils";
import {ethers, run} from "hardhat";

async function main() {
    // Addresses
    const seadrop = '0x00005EA00Ac477B1030CE78506496e8C2dE24bf5';
    const creator = '0xad2ada4B2aB6B09AC980d47a314C54e9782f1D0C';
    const feeRecipient = '0xDb5bFab9fC8D9c3F4c6fd12D686E3Fadb14F6A62';
    const admin = '0xC6C28316A74504EBA2113b0929B1b09a4c7a09F1';

    // Token config
    const maxSupply = 100;

    // Drop config
    const feeBps = 500; // 5%
    const mintPrice = parseEther('0.0001').toString();
    const maxTotalMintableByWallet = 5;
    console.log('1')
    const ERC721DiceBearPartnerSeaDrop = await ethers.getContractFactory("ERC721DiceBearPartnerSeaDrop");

    const token = await ERC721DiceBearPartnerSeaDrop.deploy(
        "Dice bear test",
        "DBT",
        admin,
        [seadrop]
    );
    await token.deployed()
    console.log('token: ', token.address)

    console.log('2')

    await run(`verify:verify`, {
        address: token.address,
        constructorArguments: [
            "Dice bear test",
            "DBT",
            admin,
            [seadrop]
        ],
    });
    console.log('3')
}
