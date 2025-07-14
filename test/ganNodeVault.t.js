const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GANNodeVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  before(async () => {
    [owner, orderBookHandler,user1,user2] =
      await ethers.getSigners();
    ganNodeFactory = await ethers.getContractFactory("GANNode");
    ganNode = await ganNodeFactory.deploy();

    ganNodeVaultFactory = await ethers.getContractFactory("GANNodeVault");
    ganNodeVaultProxy = await upgrades.deployProxy(ganNodeVaultFactory, [ganNode.target, orderBookHandler.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("GanNodeVault::", () => {
    it("Should switch on every user functions", async () => {
    //   //createSubnet
    //   await expect(await subnetProxy._createSubnets()).to.be.equals(false);
    //   await subnetProxy.connect(owner).setUserFunctionStatus(true, 0);
    //   await expect(await subnetProxy._createSubnets()).to.be.equals(true);
    //   //deleteSubnet
    //   await subnetProxy.connect(owner).setUserFunctionStatus(true, 1);
    //   //claimRewards
    //   await subnetProxy.connect(owner).setUserFunctionStatus(true, 3);
    //   //castVotes
    //   await subnetProxy.connect(owner).setUserFunctionStatus(true, 4);
    //   //uncastVotes
    //   await subnetProxy.connect(owner).setUserFunctionStatus(true, 5);
    await ganNode.connect(owner).batchNodeMint([user1],[10],"abcd");
    console.log("Nft balance:"+await ganNode.balanceOf(user1.address));
    console.log("approval status before:"+await ganNode.isApprovedForAll(user1.address,ganNodeVaultProxy.target));
    await ganNode.connect(user1).setApprovalForAll(ganNodeVaultProxy.target,true);
    console.log("approval status after:"+await ganNode.isApprovedForAll(user1.address,ganNodeVaultProxy.target));
    await ganNodeVaultProxy.connect(owner).setLockStatus(true,0);
    await ganNodeVaultProxy.connect(user1).depositNode(2,[1,2]);
    console.log("vault Nft balance:"+await ganNode.balanceOf(ganNodeVaultProxy.target));
    await ganNodeVaultProxy.connect(orderBookHandler).unlock(user2,2);
    console.log("user2 Nft balance before:"+await ganNode.balanceOf(user2.address));
    await ganNodeVaultProxy.connect(owner).setLockStatus(true,1);
    await ganNodeVaultProxy.connect(user2).withdrawNode(1);
    console.log("user2 Nft balance after 1st:"+await ganNode.balanceOf(user2.address));
    await ganNodeVaultProxy.connect(user2).withdrawNode(1);
    console.log("user2 Nft balance after 2nd:"+await ganNode.balanceOf(user2.address));
    });
  });

});
