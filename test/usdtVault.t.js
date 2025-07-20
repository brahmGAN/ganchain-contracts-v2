const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("USDTVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  before(async () => {
    [owner, orderBookHandler,user1,user2] =
      await ethers.getSigners();
    mockUsdtFactory = await ethers.getContractFactory("MockUSDT");
    mockUsdt = await mockUsdtFactory.deploy(owner.address);

    usdtVaultFactory = await ethers.getContractFactory("USDTVault");
    usdtVaultProxy = await upgrades.deployProxy(usdtVaultFactory, [mockUsdt.target,orderBookHandler.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("USDTVault::", () => {
    it("Should switch on every user functions", async () => {
        console.log("owner balance before: "+await mockUsdt.balanceOf(owner.address));
        console.log("Contract balance before: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        await usdtVaultProxy.connect(owner).setLockStatus(true,0);
        await usdtVaultProxy.connect(owner).setLockStatus(true,1);
        await expect(usdtVaultProxy.connect(owner).depositUsdt(6 * 10**6)).
        to.be.revertedWithCustomError(usdtVaultProxy,"ContractIsNotApproved");
        await mockUsdt.connect(owner).approve(usdtVaultProxy.target,69 * 10**6);
        await usdtVaultProxy.connect(owner).depositUsdt(69 * 10**6);
        console.log("Contract balance after: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        await usdtVaultProxy.connect(orderBookHandler).unlock(user2,70 * 10**6); 

        await expect(usdtVaultProxy.connect(user2).withdrawUsdt(71 * 10**6)).
        to.be.revertedWithCustomError(usdtVaultProxy,"InsufficientUnlockedBalance");
        
        await usdtVaultProxy.connect(user2).withdrawUsdt(69 * 10**6);

        await expect(usdtVaultProxy.connect(user2).withdrawUsdt(1 * 10**6)).
        to.be.revertedWithCustomError(usdtVaultProxy,"inSufficientBalanceInContract");
        console.log("Contract balance third: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        console.log("user2 balance after: "+await mockUsdt.balanceOf(user2.address));
    });
  });

});
