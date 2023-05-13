import hre, { upgrades } from "hardhat";
import { expect } from "chai";
import { SenatePositions, Senate, Timelock } from "../typechain-types" 

describe("Deployment", function () {

    let senatePositions: SenatePositions;
    let senate: Senate;
    let timelock: Timelock;

    it("Should deploy the SenatePositions Contract", async function () {
        const [deployer] = await hre.ethers.getSigners();
        const nonce = await deployer.getTransactionCount();

        // Generate expected SenatePositions contract address
        const expectedSenatePositionsAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce
        });

        // Generate expected Senate contract address
        const expectedSenateAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 2, // Implementation + Proxy
        });

        // Generate expected Timelock contract address
        const expectedTimelockAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 5, // Senate Contracts + Implementation + Proxy
        });

        const SenatePositions = await hre.ethers.getContractFactory("SenatePositions");
        senatePositions = await SenatePositions.deploy(
            expectedSenateAddress,
            expectedTimelockAddress, 
            ["", "", "", "", ""],
            [63115200, 63115200, 63115200, 63115200, 63115200]
        ) as SenatePositions;
        await senatePositions.deployed();
        expect(senatePositions.address).to.properAddress;
        expect(senatePositions.address).to.equal(expectedSenatePositionsAddress);
    });

    it("Should deploy the Senate Contract", async function () {
        const [deployer] = await hre.ethers.getSigners();
        const nonce = await deployer.getTransactionCount();

        // Generate expected Senate contract address
        const expectedSenateAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 1, // Implementation + Proxy
        });

        // Generate expected Timelock contract address
        const expectedTimelockAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 4, // Senate Contracts + Implementation + Proxy
        });

        const Senate = await hre.ethers.getContractFactory("Senate");
        senate = await upgrades.deployProxy(
            Senate,
            [
                senatePositions.address, 
                expectedTimelockAddress, 
                senatePositions.address,
                51,
            ],
        ) as Senate;
        
        await senate.deployed();
        expect(senate.address).to.properAddress;
        expect(senate.address).to.equal(expectedSenateAddress);
    });

    it("Should deploy the Timelock Contract", async function () {
        const [deployer] = await hre.ethers.getSigners();
        const nonce = await deployer.getTransactionCount();

        // Generate expected Timelock contract address
        const expectedTimelockAddress = hre.ethers.utils.getContractAddress({
            from: deployer.address,
            nonce: nonce + 2, // Implementation + Proxy
        });

        const Timelock = await hre.ethers.getContractFactory("Timelock");
        timelock = await upgrades.deployProxy(
            Timelock,
            [
                172800,
                [senate.address],
                [senate.address]
            ],
        ) as Timelock;
        const tx = await timelock.deployed();
        expect(timelock.address).to.properAddress;
        expect(timelock.address).to.equal(expectedTimelockAddress);
    });

    it("Has correct Senate address in SenatePositions", async function () {
        expect(await senatePositions.senateContract()).to.equal(senate.address);
    });

    it("Has correct Timelock address in SenatePositions", async function () {
        expect(await senatePositions.timelockContract()).to.equal(timelock.address);
    });

    it("Has correct Timelock address in Senate", async function () {
        expect(await senate.timelock()).to.equal(timelock.address);
    });
    it("Has correct SenatePositions address in Senate", async function () {
        expect(await senate.senatePositionsContract()).to.equal(senatePositions.address);
    });

    it("Has correct Proposer and Executor address in Timelock", async function () {
        expect(await timelock.hasProposalRole(senate.address)).to.equal(true);
        expect(await timelock.hasExecutionRole(senate.address)).to.equal(true);
    });

});

