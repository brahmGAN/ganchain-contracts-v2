const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Providers", () => {
  let owner;
  let updater;
  let provider1;
  let provider2;
  let provider3;
  before(async () => {
    [owner, updater, provider1,provider2,provider3] =
      await ethers.getSigners();
    providersFactory = await ethers.getContractFactory("providers");
    providersProxy = await upgrades.deployProxy(providersFactory, [updater.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("Switch on all user callable functions", () => {
    it("Should switch on every user functions", async () => {
      //_registerProvider
      await expect(await providersProxy._registerProvider()).to.be.equals(false);
      await providersProxy.connect(updater).setLockStatus(true, 0);
      await expect(await providersProxy._registerProvider()).to.be.equals(true);
      //_claimAllRewards
      await providersProxy.connect(updater).setLockStatus(true, 1);
      //claimRewards
      await providersProxy.connect(updater).setLockStatus(true, 2);
    });
  });

  describe("Owner sets all the rewards", () => {
    it("Should set individual provider rewards", async () => {
      //setRewards
      await providersProxy
        .connect(updater)
        .setRewards(
          provider1,
          ethers.parseEther("60")
        );
    });

    it("Should set batch provider rewards", async () => {
        //setBatchRewards
        await providersProxy
          .connect(updater)
          .setBatchRewards(
            [provider1,provider2,provider3],
            [ethers.parseEther("9"),ethers.parseEther("10"),ethers.parseEther("15")]
          );
      });
  });

  describe("Interact with all user callable functions", () => {
    it("Should register providers", async () => {
      await providersProxy
        .connect(provider1)
        .registerProvider();

        await expect(await providersProxy._registered(provider1)).to.be.equals(true);
    });

    it("Should claim all rewards", async () => {
        await expect(await providersProxy._pendingRewards(provider1)).to.be.equals(ethers.parseEther("69"));

        await expect(await ethers.provider.getBalance(await providersProxy.getAddress())).to.be.equals(ethers.parseEther("0"));

        await owner.sendTransaction({
            to: await providersProxy.getAddress(),
            value: ethers.parseEther("100") // Adjust amount as needed
        });
        
        await expect(await ethers.provider.getBalance(await providersProxy.getAddress())).to.be.equals(ethers.parseEther("100"));

        await providersProxy
        .connect(provider1)
        .claimAllRewards();

        await expect(await ethers.provider.getBalance(await providersProxy.getAddress())).to.be.equals(ethers.parseEther("31"));

        await expect(await providersProxy._pendingRewards(provider1)).to.be.equals(0);
      });

      it("Should claim dynamic rewards", async () => {

        await expect(await providersProxy._pendingRewards(provider3)).to.be.equals(ethers.parseEther("15"));

        await providersProxy
        .connect(provider3)
        .claimRewards(ethers.parseEther("9"));

        await expect(await providersProxy._pendingRewards(provider3)).to.be.equals(ethers.parseEther("6"));
      });
  });
});
