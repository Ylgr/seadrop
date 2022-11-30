import { ethers, run, network} from "hardhat";
import {parseEther} from "ethers/lib/utils";
import {token} from "../typechain-types/lib/openzeppelin-contracts/contracts";

async function main() {
    // Addresses
    const seadrop = '0x00005EA00Ac477B1030CE78506496e8C2dE24bf5';
    const creator = '0xad2ada4B2aB6B09AC980d47a314C54e9782f1D0C';
    const feeRecipient = '0xDb5bFab9fC8D9c3F4c6fd12D686E3Fadb14F6A62';

    // Token config
    const maxSupply = 100;

    // Drop config
    const feeBps = 500; // 5%
    const mintPrice = parseEther('0.0001').toString();
    const maxTotalMintableByWallet = 5;
    console.log('1')
    const ERC721SeaDrop = await ethers.getContractFactory("ERC721SeaDrop");

    // Attach deployed contract to continue migration code
    // const token = ERC721SeaDrop.attach('0x2ab4Cd18057C7a3df47902cD5F28E628A00f17E0')

    const token = await ERC721SeaDrop.deploy(
        "My Example Token",
        "ExTKN",
        [seadrop]
    );

    await token.deployed()
    console.log('2')

    await run(`verify:verify`, {
        address: token.address,
        constructorArguments: [
            "My Example Token",
            "ExTKN",
            [seadrop]
        ],
    });
    console.log('3')

    // Configure the token.
    await token.setMaxSupply(maxSupply);
    console.log('4')

    // Configure the drop parameters.
    await token.updateCreatorPayoutAddress(seadrop, creator);
    console.log('5')

    await token.updateAllowedFeeRecipient(seadrop, feeRecipient, true);
    console.log('6')

    const now = Math.round((new Date()).getTime() / 1000);
    await token.updatePublicDrop(
        seadrop,
        {
            mintPrice: mintPrice,
            startTime: now, // start time
            endTime: now + 1000, // end time
            maxTotalMintableByWallet: maxTotalMintableByWallet,
            feeBps: feeBps,
            restrictFeeRecipients: true
        }
    );
    console.log('Done')

    const SeaDrop = await ethers.getContractFactory("SeaDrop");
    const seaDrop = SeaDrop.attach('0x00005EA00Ac477B1030CE78506496e8C2dE24bf5')
    await seaDrop.mintPublic(token.address, feeRecipient, '0x0000000000000000000000000000000000000000', 3,
        {value: parseEther('0.0003').toString()}
    )
    console.log('Mint done!')
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
