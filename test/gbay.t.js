const { ethers } = require("hardhat");
const { expect, use } = require("chai");

describe("GBay", () => {
  let owner;
  let escrowHandler;
  let user1;
  let user2;
  before(async () => {
    [owner, escrowHandler, user1, user2] = await ethers.getSigners();

    GBayFactory = await ethers.getContractFactory("GBayEscrow");
    GBayProxy = await upgrades.deployProxy(
      GBayFactory,
      [escrowHandler.address],
      {
        initializer: "initialize",
        from: owner.address,
      }
    );
  });

  describe("GBay", () => {
    it("Should switch on every user functions", async () => {
        await GBayProxy.connect(owner).setLockStatus(true,0);
        await GBayProxy.connect(owner).setLockStatus(true,1);
        await GBayProxy.connect(owner).setLockStatus(true,2);
        await GBayProxy.connect(owner).setLockStatus(true,3);
    });
    it("Should let users create order",async ()=>{

    });
  });
});
