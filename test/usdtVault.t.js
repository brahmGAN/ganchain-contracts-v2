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
    usdtVaultProxy = await upgrades.deployProxy(usdtVaultFactory, [mockUsdt.target], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("USDTVault::", () => {
    it("Should switch on every user functions", async () => {
        console.log("owner balance before: "+await mockUsdt.balanceOf(owner.address));
        console.log("Contract balance before: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        await mockUsdt.connect(owner).approve(usdtVaultProxy.target,69 * 10**6);
        await usdtVaultProxy.connect(owner).depositUsdt(69 * 10**6);
        console.log("Contract balance after: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        await usdtVaultProxy.connect(owner).setOrderbook(orderBookHandler);
        await usdtVaultProxy.connect(orderBookHandler).unlock(user2,7 * 10**6); 
        await usdtVaultProxy.connect(user2).withdrawUsdt(1 * 10**6);
        console.log("Contract balance third: "+await mockUsdt.balanceOf(usdtVaultProxy.target));
        console.log("user2 balance after: "+await mockUsdt.balanceOf(user2.address));
    });
  });

});
