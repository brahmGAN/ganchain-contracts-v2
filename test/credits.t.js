const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Buy Credits", () => {
  let owner;
  let fundsHandler;
  let user1;
  let fundsHandler2;
  let fundsHandlerBalanceBefore;
  before(async () => {
    [owner, fundsHandler, user1, fundsHandler2] = await ethers.getSigners();
    creditsFactory = await ethers.getContractFactory("credits");
    creditsProxy = await upgrades.deployProxy(
      creditsFactory,
      [fundsHandler.address],
      {
        initializer: "initialize",
        from: owner.address,
      }
    );
  });

  describe("Switch on all user callable functions", () => {
    it("Should switch on every user functions", async () => {
      await expect(await creditsProxy._buyCredits()).to.be.equals(false);
      await creditsProxy.connect(owner).setLockStatus(true,1);
      await expect(await creditsProxy._buyCredits()).to.be.equals(true);
    });
  });

  describe("Buying credits:",() => {
    it("Should let users buy credits", async () => {
        fundsHandlerBalanceBefore = await ethers.provider.getBalance(fundsHandler.address);
        await creditsProxy.connect(user1).buyCredits(ethers.parseEther("69"),"0d603ed7-4cae-47a6-8739-12b82c5746a7",{value: ethers.parseEther("69")});
        await expect(await ethers.provider.getBalance(fundsHandler.address)).to.be.equals(fundsHandlerBalanceBefore + ethers.parseEther("69"));
    });
  });
});
