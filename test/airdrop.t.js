const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Airdrop", () => {
  let owner;
  let updater;
  let hunter1;
  let hunter2;
  let hunter3;
  before(async () => {
    [owner, updater, hunter1,hunter2,hunter3] =
      await ethers.getSigners();
    airdropFactory = await ethers.getContractFactory("gpuNetAirdrops");
    airdropProxy = await upgrades.deployProxy(airdropFactory, [updater.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("Switch on all user callable functions", () => {
    it("Should switch on every user functions", async () => {
      //_claimAirdrops
      await expect(await airdropProxy._claimAirdrops()).to.be.equals(false);
      await airdropProxy.connect(updater).setClaimAirdropsStatus(true);
      await expect(await airdropProxy._claimAirdrops()).to.be.equals(true);
    });
  });

  describe("Owner sets all the Airdrops", () => {
    it("Should set individual airdrops", async () => {
      await airdropProxy
        .connect(updater)
        .setAirdrop(
          hunter1,
          ethers.parseEther("60")
        );
    });

    it("Should set batch Airdrops", async () => {
        await airdropProxy
          .connect(updater)
          .setBatchAirdrop(
            [hunter1,hunter2,hunter3],
            [ethers.parseEther("69"),ethers.parseEther("10"),ethers.parseEther("15")]
          );
      });
  });

  describe("Interact with all user callable functions", () => {
    it("Should claim Airdrops", async () => {
        await expect(await airdropProxy._totalClaimedAirdrop(hunter1)).to.be.equals(ethers.parseEther("0"));
        await expect(await airdropProxy._airdrop(hunter1)).to.be.equals(ethers.parseEther("69"));

        await owner.sendTransaction({
            to: await airdropProxy.getAddress(),
            value: ethers.parseEther("100") 
        });
      await airdropProxy
        .connect(hunter1)
        .claimAirdrops();

        await expect(await airdropProxy._totalClaimedAirdrop(hunter1)).to.be.equals(ethers.parseEther("69"));
        await expect(await airdropProxy._airdrop(hunter1)).to.be.equals(ethers.parseEther("0"));
    });
  });
});
