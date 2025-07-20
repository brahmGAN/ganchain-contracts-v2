const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GANNodeVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
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
});
