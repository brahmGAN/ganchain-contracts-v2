const { ethers, upgrades } = require("hardhat");
const { expect, use } = require("chai");

describe("USDTVault", () => {
  let owner;
  let orderBookHandler;
  let user1;
  let user2;
  let totalDepositedBeforeUpgrade;
  let v2UsdtVaultProxy; 
  before(async () => {
    [owner, orderBookHandler, user1, user2] = await ethers.getSigners();
    mockUsdtFactory = await ethers.getContractFactory("MockUSDT");
    mockUsdt = await mockUsdtFactory.deploy(owner.address);

    usdtVaultFactory = await ethers.getContractFactory("USDTVault");
    usdtVaultProxy = await upgrades.deployProxy(
      usdtVaultFactory,
      [mockUsdt.target, orderBookHandler.address],
      {
        initializer: "initialize",
        from: owner.address,
      }
    );
  });

  describe("USDTVault::", () => {
    it("Should switch on every user functions", async () => {
      console.log(
        "owner balance before: " + (await mockUsdt.balanceOf(owner.address))
      );
      console.log(
        "Contract balance before: " +
          (await mockUsdt.balanceOf(usdtVaultProxy.target))
      );
      await usdtVaultProxy.connect(owner).setLockStatus(true, 0);
      await usdtVaultProxy.connect(owner).setLockStatus(true, 1);
      await expect(
        usdtVaultProxy.connect(owner).depositUsdt(6 * 10 ** 6)
      ).to.be.revertedWithCustomError(usdtVaultProxy, "ContractIsNotApproved");
      await mockUsdt
        .connect(owner)
        .approve(usdtVaultProxy.target, 69 * 10 ** 6);
      await usdtVaultProxy.connect(owner).depositUsdt(69 * 10 ** 6);
      console.log(
        "Contract balance after: " +
          (await mockUsdt.balanceOf(usdtVaultProxy.target))
      );
      await usdtVaultProxy
        .connect(orderBookHandler)
        .unlock(user2, 70 * 10 ** 6);

      await expect(
        usdtVaultProxy.connect(user2).withdrawUsdt(71 * 10 ** 6)
      ).to.be.revertedWithCustomError(
        usdtVaultProxy,
        "InsufficientUnlockedBalance"
      );

      await usdtVaultProxy.connect(user2).withdrawUsdt(69 * 10 ** 6);

      await expect(
        usdtVaultProxy.connect(user2).withdrawUsdt(1 * 10 ** 6)
      ).to.be.revertedWithCustomError(
        usdtVaultProxy,
        "inSufficientBalanceInContract"
      );
      console.log(
        "Contract balance third: " +
          (await mockUsdt.balanceOf(usdtVaultProxy.target))
      );
      console.log(
        "user2 balance after: " + (await mockUsdt.balanceOf(user2.address))
      );
    });
  });

  describe("Contract upgrade:",()=>{
    it("Should upgrade to the new USDT vault contract:",async()=>{
      totalDepositedBeforeUpgrade = await usdtVaultProxy.totalDeposited(); 
      const v2UsdtVaultFactory = await ethers.getContractFactory("v2USDTVault");
      v2UsdtVaultProxy = await upgrades.upgradeProxy(
        usdtVaultProxy.target, 
        v2UsdtVaultFactory
      );
      await expect(await v2UsdtVaultProxy.totalDeposited()).to.equals(totalDepositedBeforeUpgrade);
    });
  });

  describe("Withdraw after upgrading:",()=>{
    it("Should fail if anyone other than orderBookHandler tries to withdraw",async()=>{
      await v2UsdtVaultProxy.connect(owner).setLockStatus(true, 2);
      await expect(
        v2UsdtVaultProxy.connect(user1).withdrawUsdtFor(user1.address, 1 * 10 ** 6)
      ).to.be.revertedWith("USDTVault: Only Orderbook can call this");
    });

    it("Should let orderbook handler withdraw on user1's behalf",async()=>{
      await mockUsdt.connect(owner).transfer(v2UsdtVaultProxy.target, 10 * 10 ** 6);
      await v2UsdtVaultProxy.connect(owner).setLockStatus(true, 2);
      const before = await mockUsdt.balanceOf(user1.address);
      await v2UsdtVaultProxy
        .connect(orderBookHandler)
        .withdrawUsdtFor(user1.address, 5 * 10 ** 6);
      const after = await mockUsdt.balanceOf(user1.address);
      const delta = ethers.parseUnits("5", 6);
      expect(after).to.equal(before + delta);
    });
  });
});
