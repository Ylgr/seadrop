import {ethers} from "hardhat";
import {randomHex} from "./utils/encoding";
import {faucet} from "./utils/faucet";
import {BigNumber, BigNumberish, Wallet} from "ethers";
import {ERC721DiceBearSeaDrop, ERC721PartnerSeaDrop, ISeaDrop} from "../typechain-types";
import {PromiseOrValue} from "../typechain-types/common";

describe("ERC721DiceBearSeaDrop", () => {
    let owner: Wallet;
    let admin: Wallet;
    let minter: Wallet;
    const {provider} = ethers;
    let seadrop: ISeaDrop;
    let token: ERC721DiceBearSeaDrop;
    let publicDrop: { mintPrice: PromiseOrValue<BigNumberish>; maxTotalMintableByWallet: PromiseOrValue<BigNumberish>; startTime: PromiseOrValue<BigNumberish>; endTime: PromiseOrValue<BigNumberish>; feeBps: PromiseOrValue<BigNumberish>; restrictFeeRecipients: PromiseOrValue<boolean>; };

    before(async () => {
        // Set the wallets
        owner = new ethers.Wallet(randomHex(32), provider);
        admin = new ethers.Wallet(randomHex(32), provider);
        minter = new ethers.Wallet(randomHex(32), provider);

        // Add eth to wallets
        for (const wallet of [owner, admin, minter]) {
            await faucet(wallet.address, provider);
        }

        // Deploy SeaDrop
        const SeaDrop = await ethers.getContractFactory("SeaDrop", owner);
        seadrop = await SeaDrop.deploy();

        // Deploy token
        const ERC721DiceBearSeaDrop = await ethers.getContractFactory(
            "ERC721DiceBearSeaDrop",
            owner
        );
        token = await ERC721DiceBearSeaDrop.deploy("bear", "BEAR", [
            seadrop.address,
        ]);

        publicDrop = {
            mintPrice: "100000000000000000", // 0.1 ether
            maxTotalMintableByWallet: 10,
            startTime: Math.round(Date.now() / 1000) - 100,
            endTime: Math.round(Date.now() / 1000) + 100,
            feeBps: 1000,
            restrictFeeRecipients: true,
        };
    })

    it("check uri", async () => {
        const value = BigNumber.from(publicDrop.mintPrice).mul(3);

        const uri = await token.baseURI()
        console.log('uri: ', uri)

        await token.connect(owner).updatePublicDrop(seadrop.address, publicDrop);
        await token.setMaxSupply(5);

        const feeRecipient = new ethers.Wallet(randomHex(32), provider);
        await token
            .connect(owner)
            .updateAllowedFeeRecipient(seadrop.address, feeRecipient.address, true);
        await token.connect(owner).updateCreatorPayoutAddress(seadrop.address, owner.address);

        await seadrop
            .connect(minter)
            .mintPublic(
                token.address,
                feeRecipient.address,
                ethers.constants.AddressZero,
                3,
                { value }
            )
        console.log('uri 1:', await token.tokenURI(1))
    })
})
