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

    it("Should revert when buying with amount mismatch", async () => {
        await expect(
          creditsProxy.connect(user1).buyCredits(ethers.parseEther("100"), "different-id-1", {value: ethers.parseEther("50")})
        ).to.be.revertedWithCustomError(creditsProxy, "incorrectAmount");
    });

    it("Should revert when using duplicate id", async () => {
        await expect(
          creditsProxy.connect(user1).buyCredits(ethers.parseEther("10"), "0d603ed7-4cae-47a6-8739-12b82c5746a7", {value: ethers.parseEther("10")})
        ).to.be.revertedWithCustomError(creditsProxy, "IdAlreadyUsed");
    });

    it("Should revert when amount is 0", async () => {
        await expect(
          creditsProxy.connect(user1).buyCredits(0, "new-id-1", {value: 0})
        ).to.be.revertedWithCustomError(creditsProxy, "incorrectAmount");
    });

    it("Should check ID status tracking", async () => {
        const testId = "tracking-test-id";
        const amount = ethers.parseEther("50");
        await creditsProxy.connect(user1).buyCredits(amount, testId, {value: amount});
        expect(await creditsProxy._idStatus(testId)).to.equal(amount);
    });
  });

  describe("Owner functions:", () => {
    it("Should set funds handler", async () => {
        await creditsProxy.connect(owner).setFundsHandler(fundsHandler2.address);
        
        expect(await creditsProxy._fundsHandler()).to.equal(fundsHandler2.address);
    });

    it("Should revert setLockStatus with wrong lock value", async () => {
        await expect(
          creditsProxy.connect(owner).setLockStatus(false, 0)
        ).to.be.revertedWithCustomError(creditsProxy, "wrongFunctionType");
    });

    it("Should revert setLockStatus when called by non-owner", async () => {
        await expect(
          creditsProxy.connect(user1).setLockStatus(false, 1)
        ).to.be.reverted;
    });

    it("Should revert setFundsHandler when called by non-owner", async () => {
        await expect(
          creditsProxy.connect(user1).setFundsHandler(fundsHandler2.address)
        ).to.be.reverted;
    });
  });
});
