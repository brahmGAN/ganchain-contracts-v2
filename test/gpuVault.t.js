const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GPUVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  let v2GPUVaultProxy;
  before(async () => {
    [owner, orderBookHandler, user1, user2] = await ethers.getSigners();

    GPUVaultFactory = await ethers.getContractFactory("GPUVault");
    GPUVaultProxy = await upgrades.deployProxy(
      GPUVaultFactory,
      [orderBookHandler.address],
      {
        initializer: "initialize",
        from: owner.address,
      }
    );
  });

  describe("GPUVault::", () => {
    it("Should switch on every user functions", async () => {
      await GPUVaultProxy.connect(owner).setLockStatus(true, 0);
      console.log(
        "Contract balance before:" +
          (await ethers.provider.getBalance(GPUVaultProxy.target))
      );
      await GPUVaultProxy.connect(user1).depositGpu({
        value: ethers.parseEther("5"),
      });
      console.log("Total deposited: " + (await GPUVaultProxy.totalDeposited()));
      console.log(
        "Contract balance After:" +
          (await ethers.provider.getBalance(GPUVaultProxy.target))
      );
      await GPUVaultProxy.connect(orderBookHandler).unlock(
        user2,
        ethers.parseEther("6")
      );
      console.log(
        "user2 unlocked balance before:" +
          (await GPUVaultProxy.unlockedBalances(user2.address))
      );
      await GPUVaultProxy.connect(owner).setLockStatus(true, 1);
      await expect(
        GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("100"))
      ).to.be.revertedWithCustomError(
        GPUVaultProxy,
        "InsufficientUnlockedBalance"
      );
      await GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("2"));
      console.log(
        "user2 unlocked balance after:" +
          (await GPUVaultProxy.unlockedBalances(user2.address))
      );
      await GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("3"));
      await expect(
        GPUVaultProxy.connect(user2).withdrawGpu(ethers.parseEther("1"))
      ).to.be.revertedWithCustomError(
        GPUVaultProxy,
        "inSufficientBalanceInContract"
      );
    });
  });

  describe("v2 GPU vault Contract upgrade:", () => {
    it("Should upgrade to the new GPU vault contract:", async () => {
      totalDepositedBeforeUpgrade = await GPUVaultProxy.totalDeposited();
      const v2GPUVaultFactory = await ethers.getContractFactory("v2GPUVault");
      v2GPUVaultProxy = await upgrades.upgradeProxy(
        GPUVaultProxy.target,
        v2GPUVaultFactory
      );
      await expect(await v2GPUVaultProxy.totalDeposited()).to.equals(
        totalDepositedBeforeUpgrade
      );
    });
  });

  describe("Withdraw after upgrading:", () => {
    it("Should fail if anyone other than orderBookHandler tries to withdraw", async () => {
      await v2GPUVaultProxy.connect(owner).setLockStatus(true, 2);
      await expect(
        v2GPUVaultProxy
          .connect(user1)
          .withdrawGpuFor(user1.address, ethers.parseEther("1"))
      ).to.be.revertedWith("GPUVault: Only Orderbook can call this");
    });

    it("Should let orderbook handler withdraw on user1's behalf", async () => {
      await owner.sendTransaction({
        to: v2GPUVaultProxy.target,
        value: ethers.parseEther("10"),
      });
      await v2GPUVaultProxy.connect(owner).setLockStatus(true, 2);
      const before = await ethers.provider.getBalance(user1.address);
      const tx = await v2GPUVaultProxy
        .connect(orderBookHandler)
        .withdrawGpuFor(user1.address, ethers.parseEther("2"));
      await tx.wait();
      const after = await ethers.provider.getBalance(user1.address);
      expect(after).to.equal(before + ethers.parseEther("2"));
    });
  });
});
