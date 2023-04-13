import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "@ethersproject/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import CensorsArtifact from "../artifacts/contracts/Censors.sol/Censors.json";
import ConsulsArtifact from "../artifacts/contracts/Consuls.sol/Consuls.json";
import MockSenateArtifact from "../artifacts/contracts/MockSenate.sol/MockSenate.json";

describe("Censors", () => {
  let Censors: Contract;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let ownerAddress: string;
  let addr1Address: string;
  let addr2Address: string;

  beforeEach(async () => {
    const CensorsFactory = await ethers.getContractFactory("Censors");
    [owner, addr1, addr2] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    addr1Address = await addr1.getAddress();
    addr2Address = await addr2.getAddress();

    Censors = await CensorsFactory.deploy(
      "https://censor-metadata.example.com",
      30 * 24 * 60 * 60,
      addr1Address,
      addr2Address
    );
    await Censors.deployed();
  });

  describe("mint", () => {
    it("should mint a new Censor token to the given address", async () => {
      await expect(Censors.connect(addr1).mint(ownerAddress))
        .to.emit(Censors, "Transfer")
        .withArgs(ethers.constants.AddressZero, ownerAddress, 1);

      expect(await Censors.ownerOf(1)).to.equal(ownerAddress);
      expect(await Censors.censorCount()).to.equal(1);
    });

    it("should not allow non-Senate Voting Contract to mint Censor tokens", async () => {
      await expect(Censors.connect(addr2).mint(addr1Address)).to.be.revertedWith(
        "TIDUS: Only the Senate Voting Contract can mint Censors."
      );
    });
  });

  describe("burn", () => {
    beforeEach(async () => {
      await Censors.connect(addr1).mint(ownerAddress);
    });

    it("should burn a Censor token with the given token ID", async () => {
      await expect(Censors.connect(owner).burn(1))
        .to.emit(Censors, "Transfer")
        .withArgs(ownerAddress, ethers.constants.AddressZero, 1);

      expect(await Censors.censorCount()).to.equal(1);
      await expect(Censors.ownerOf(1)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("should not allow non-owners to burn a Censor token", async () => {
      await expect(Censors.connect(addr1).burn(1)).to.be.revertedWith(
        "TIDUS: Only the Senate Voting Contract or Owner can burn the token."
      );
    });
  });
  describe("isCensor", () => {
    beforeEach(async () => {
      await Censors.connect(addr1).mint(ownerAddress);
    });

    it("should return true if an address is a current censor", async () => {
      expect(await Censors.isCensor(ownerAddress)).to.be.true;
    });

    it("should return false if an address is not a current censor", async () => {
      expect(await Censors.isCensor(addr1Address)).to.be.false;
    });
  });

  describe("updateMetadata", () => {
    const newMetadata = "https://new-censor-metadata.example.com";

    it("should update the metadata URI", async () => {
      await Censors.connect(owner).updateMetadata(newMetadata);
      expect(await Censors.tokenURI()).to.equal(newMetadata);
    });

    it("should not allow non-owners to update the metadata URI", async () => {
      await expect(Censors.connect(addr1).updateMetadata(newMetadata)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("updateTimelock", () => {
    it("should update the timelock address", async () => {
      await Censors.connect(owner).updateTimelock(addr1Address);
      expect(await Censors.timelock()).to.equal(addr1Address);
    });

    it("should not allow non-owners to update the timelock address", async () => {
      await expect(Censors.connect(addr1).updateTimelock(addr1Address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("updateSenateAddress", () => {
    it("should update the Senate Voting Contract address", async () => {
      await Censors.connect(owner).updateSenateAddress(addr1Address);
      expect(await Censors.senateVotingContract()).to.equal(addr1Address);
    });

    it("should not allow non-owners to update the Senate Voting Contract address", async () => {
      await expect(Censors.connect(addr1).updateSenateAddress(addr1Address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });
})
"