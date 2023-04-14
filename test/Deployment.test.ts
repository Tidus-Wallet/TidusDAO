import { expect } from "chai";
import hre from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { SenatePositions } from "../typechain-types" 

describe("Deployment", function () {

    let senatePositions: SenatePositions;

    it("Should deploy the SenatePositions Contract", async function () {
        // Get current nonce
        const [deployer] = await ethers.getSigners();
        const nonce = await deployer.getTransactionCount();

        // Generate expected Senate contract address
        const expectedSenateAddress = ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 2, // Implementation + Proxy
        });

        // Generate expected Timelock contract address
        const expectedTimelockAddress = ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 4, // Senate Contracts + Implementation + Proxy
        });

        const SenatePositions = await ethers.getContractFactory("SenatePositions");
        senatePositions = await SenatePositions.deploy(
            expectedSenateAddress,
            expectedTimelockAddress, 
            ["", "", "", "", ""],
            ["", "", "", "", ""]
        );
        await senatePositions.deployed();
        expect(senatePositions.address).to.properAddress;
    });

    it("Should deploy the Senate Contract", async function () {
        // Get current nonce
        const [deployer] = await ethers.getSigners();
        const nonce = await deployer.getTransactionCount();

        // Generate expected Senate contract address
        const expectedSenateAddress = ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 2, // Implementation + Proxy
        });

        // Generate expected Timelock contract address
        const expectedTimelockAddress = ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 4, // Senate Contracts + Implementation + Proxy
        });

        const Senate = await ethers.getContractFactory("Senate");
        const senate = await upgrades.deployProxy(
            Senate,
            [
                senatePositions.address, 
                expectedTimelockAddress, 
                senatePositions.address
            ],
        );
        
        await senate.deployed();

        expect(senate.address).to.properAddress;
    });


});

