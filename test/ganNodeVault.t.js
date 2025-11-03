const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GANNodeVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  let v2GanNodeVaultProxy;
  before(async () => {
    [owner, orderBookHandler, user1, user2] = await ethers.getSigners();
    ganNodeFactory = await ethers.getContractFactory("GANNode");
    ganNode = await ganNodeFactory.deploy();

    ganNodeVaultFactory = await ethers.getContractFactory("GANNodeVault");
    ganNodeVaultProxy = await upgrades.deployProxy(
      ganNodeVaultFactory,
      [ganNode.target, orderBookHandler.address],
      {
        initializer: "initialize",
        from: owner.address,
      }
    );
  });

  describe("GanNodeVault::", () => {
    it("Should switch on every user functions", async () => {
      await ganNode.connect(owner).batchNodeMint([user1], [10], "abcd");
      console.log("Nft balance:" + (await ganNode.balanceOf(user1.address)));
      await ganNodeVaultProxy.connect(owner).setLockStatus(true, 0);
      await ganNodeVaultProxy.connect(owner).setLockStatus(true, 1);
      await expect(
        ganNodeVaultProxy.connect(user1).depositNode(2, [1, 2, 3])
      ).to.be.revertedWithCustomError(ganNodeVaultProxy, "incorrectArraySize");
      console.log(
        "approval status before:" +
          (await ganNode.isApprovedForAll(
            user1.address,
            ganNodeVaultProxy.target
          ))
      );
      await expect(
        ganNodeVaultProxy.connect(user1).depositNode(2, [1, 2])
      ).to.be.revertedWithCustomError(ganNodeVaultProxy, "contractNotApproved");
      await ganNode
        .connect(user1)
        .setApprovalForAll(ganNodeVaultProxy.target, true);
      console.log(
        "approval status after:" +
          (await ganNode.isApprovedForAll(
            user1.address,
            ganNodeVaultProxy.target
          ))
      );
      await ganNodeVaultProxy.connect(user1).depositNode(2, [1, 2]);
      console.log(
        "vault Nft balance:" +
          (await ganNode.balanceOf(ganNodeVaultProxy.target))
      );
      await expect(ganNodeVaultProxy.connect(owner).unlock(user2, 3)).to.be
        .reverted;
      await ganNodeVaultProxy.connect(orderBookHandler).unlock(user2, 3);
      console.log(
        "user2 Nft balance before:" + (await ganNode.balanceOf(user2.address))
      );
      await expect(
        ganNodeVaultProxy.connect(user2).withdrawNode(4)
      ).to.be.revertedWithCustomError(
        ganNodeVaultProxy,
        "InsufficientUnlockedBalance"
      );
      await ganNodeVaultProxy.connect(user2).withdrawNode(2);
      await expect(
        ganNodeVaultProxy.connect(user2).withdrawNode(1)
      ).to.be.revertedWithCustomError(
        ganNodeVaultProxy,
        "inSufficientBalanceInContract"
      );
      console.log(
        "user2 Nft balance:" + (await ganNode.balanceOf(user2.address))
      );
    });
  });

  describe("v2 GANNode vault Contract upgrade:", () => {
    it("Should upgrade to the new GANNode vault contract:", async () => {
      totalDepositedBeforeUpgrade = await ganNodeVaultProxy._totalDeposited();
      const v2GanNodeVaultFactory = await ethers.getContractFactory(
        "v2GANNodeVault"
      );
      v2GanNodeVaultProxy = await upgrades.upgradeProxy(
        ganNodeVaultProxy.target,
        v2GanNodeVaultFactory
      );
      await expect(await v2GanNodeVaultProxy._totalDeposited()).to.equals(
        totalDepositedBeforeUpgrade
      );
    });
  });

  describe("Withdraw after upgrading:", () => {
    it("Should fail if anyone other than orderBookHandler tries to withdraw", async () => {
      await v2GanNodeVaultProxy.connect(owner).setLockStatus(true, 2);
      await expect(
        v2GanNodeVaultProxy.connect(user1).withdrawNodeFor(user1.address, 1)
      ).to.be.revertedWith("GPUVault: Only Orderbook handler can call this");
    });

    it("Should let orderbook handler withdraw on user1's behalf", async () => {
      await v2GanNodeVaultProxy.connect(owner).setLockStatus(true, 0);
      await ganNode
        .connect(user1)
        .setApprovalForAll(v2GanNodeVaultProxy.target, true);
      await v2GanNodeVaultProxy.connect(user1).depositNode(2, [3, 4]);
      const before = await ganNode.balanceOf(user1.address);
      await v2GanNodeVaultProxy.connect(owner).setLockStatus(true, 2);
      await v2GanNodeVaultProxy
        .connect(orderBookHandler)
        .withdrawNodeFor(user1.address, 1);
      const after = await ganNode.balanceOf(user1.address);
      expect(after).to.equal(before + 1n);

      console.log(
        "Current node balance:",
        await ganNode.balanceOf(v2GanNodeVaultProxy.target)
      );

      // await v2GanNodeVaultProxy
      //   .connect(orderBookHandler)
      //   .withdrawNodeFor(user1.address, 2);
    });
  });
});
