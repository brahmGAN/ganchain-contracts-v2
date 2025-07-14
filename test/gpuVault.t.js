const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GPUVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  before(async () => {
    [owner, orderBookHandler,user1,user2] =
      await ethers.getSigners();

    GPUVaultFactory = await ethers.getContractFactory("GPUVault");
    GPUVaultProxy = await upgrades.deployProxy(GPUVaultFactory, [orderBookHandler.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("GPUVault::", () => {
    it("Should switch on every user functions", async () => {
        await GPUVaultProxy.connect(owner).setLockStatus(true,0);
        console.log("Contract balance before:"+await ethers.provider.getBalance(GPUVaultProxy.target));
        await GPUVaultProxy.connect(user1).depositGpu({value:ethers.parseEther("10")});
        console.log("Contract balance After:"+await ethers.provider.getBalance(GPUVaultProxy.target));
        await GPUVaultProxy.connect(orderBookHandler).unlock(user2,ethers.parseEther("5"));
        console.log("user2 unlocked balance before:"+await GPUVaultProxy.unlockedBalances(user2.address));
        await GPUVaultProxy.connect(owner).setLockStatus(true,1);
        await GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("2"));
        console.log("user2 unlocked balance after:"+await GPUVaultProxy.unlockedBalances(user2.address));
        await GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("3"));
    });
  });

});
