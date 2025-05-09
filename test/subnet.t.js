const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Subnet", () => {
  let owner;
  let updater;
  let newUpdater;
  let king1;
  let king2;
  let king3;
  let queen1;
  let queen2;
  before(async () => {
    [owner, updater, king1, king2, king3, queen1, queen2, newUpdater] =
      await ethers.getSigners();
    subnetFactory = await ethers.getContractFactory("Subnet");
    subnetProxy = await upgrades.deployProxy(subnetFactory, [updater.address], {
      initializer: "initialize",
      from: owner.address,
    });
  });

  describe("Switch on all user callable functions", () => {
    it("Should switch on every user functions", async () => {
      //createSubnet
      await expect(await subnetProxy._createSubnets()).to.be.equals(false);
      await subnetProxy.connect(owner).setUserFunctionStatus(true, 0);
      await expect(await subnetProxy._createSubnets()).to.be.equals(true);
      //deleteSubnet
      await subnetProxy.connect(owner).setUserFunctionStatus(true, 1);
      //claimRewards
      await subnetProxy.connect(owner).setUserFunctionStatus(true, 3);
      //castVotes
      await subnetProxy.connect(owner).setUserFunctionStatus(true, 4);
      //uncastVotes
      await subnetProxy.connect(owner).setUserFunctionStatus(true, 5);
    });
  });

  describe("Owner sets all the user related details", () => {
    it("Should set all the details of the users", async () => {
      //setKingRewards
      await subnetProxy
        .connect(owner)
        .setKingRewards(
          [king1, king2],
          [ethers.parseEther("10"), ethers.parseEther("20")],
        );
      //setQueenRewards
      await subnetProxy
        .connect(owner)
        .setQueenRewards(
          [queen1, queen2],
          [ethers.parseEther("30"), ethers.parseEther("40")],
        );
      //setBatchUserMaxVotes
      await subnetProxy
        .connect(updater)
        .setBatchUserMaxVotes([queen1, queen2], [5, 10]);

      await expect(await subnetProxy._pendingRewards(queen2)).to.be.equals(
        ethers.parseEther("40"),
      );

      await expect(await subnetProxy._maxVotes(queen2)).to.be.equals(10);
    });
  });

  describe("Users should interact with all user callable functions", () => {
    it("Should create a subnet", async () => {
      await subnetProxy.connect(king1).createSubnet();
      await subnetProxy.connect(king2).createSubnet();
      await subnetProxy.connect(king3).createSubnet();
      await expect(await subnetProxy._subnetStatus(3)).to.be.equals(true);
    });
    it("Should not create multiple subnets", async () => {
      await expect(
        subnetProxy.connect(king1).createSubnet(),
      ).to.be.revertedWithCustomError(
        subnetProxy,
        "cannotCreateMultipleSubnets",
      );
    });
    it("Should delete a subnet", async () => {
      await subnetProxy.connect(king3).deleteSubnet(3);
      await expect(await subnetProxy._subnetStatus(3)).to.be.equals(false);
    });
    it("Should claim rewards", async () => {
      await owner.sendTransaction({
        to: await subnetProxy.getAddress(),
        value: ethers.parseEther("100"),
      });
      await expect(
        await subnetProxy.connect(queen2).claimRewards(ethers.parseEther("10")),
      )
        .to.emit(subnetProxy, "claimedRewards")
        .withArgs(queen2, ethers.parseEther("10"));
    });
    it("Should cast vote for multiple subnets", async () => {
      await subnetProxy.connect(queen2).castVotes([1, 2], [3, 4], 7);
      await expect(
        await subnetProxy._userVotesToSubnet(queen2.address, 2),
      ).to.be.equals(4);
    });
    it("Should un-cast vote for multiple subnets", async () => {
      await subnetProxy.connect(queen2).unCastVotes([1, 2], [1, 2], 3);
      await expect(
        await subnetProxy._userVotesToSubnet(queen2.address, 2),
      ).to.be.equals(2);
    });
  });

  describe("Call all the setter fucntions", () => {
    it("should authorizedRewardSender()", async () => {
      await expect(await subnetProxy._pendingRewards(king1)).to.be.equals(
        ethers.parseEther("10"),
      );
      await subnetProxy
        .connect(owner)
        .authorizedRewardSender(
          [king1, king2],
          [ethers.parseEther("10"), ethers.parseEther("20")],
        );
      await expect(await subnetProxy._pendingRewards(king1)).to.be.equals(
        ethers.parseEther("0"),
      );
    });
    it("should setBatchSubnetsVotes()", async () => {
      await expect(await subnetProxy._subnetVotes(6)).to.be.equals(0);
      await subnetProxy.connect(updater).setBatchSubnetsVotes([6, 9], [6, 9]);
      await expect(await subnetProxy._subnetVotes(6)).to.be.equals(6);
    });
    it("should setSubnetsVotes", async () => {
      await expect(await subnetProxy._subnetVotes(7)).to.be.equals(0);
      await subnetProxy.connect(updater).setSubnetsVotes(7, 7);
      await expect(await subnetProxy._subnetVotes(7)).to.be.equals(7);
    });
    it("should setUserMaxVotes", async () => {
      await expect(await subnetProxy._maxVotes(queen1)).to.be.equals(5);
      await subnetProxy.connect(updater).setUserMaxVotes(queen1, 69);
      await expect(await subnetProxy._maxVotes(queen1)).to.be.equals(69);
    });
    it("should setBatchUserCastedVotes", async () => {
      await expect(await subnetProxy._userCastedVotes(king1)).to.be.equals(0);
      await subnetProxy
        .connect(updater)
        .setBatchUserCastedVotes([king1, king2], [5, 6]);
      await expect(await subnetProxy._userCastedVotes(king1)).to.be.equals(5);
    });
    it("should setUserCastedVotes", async () => {
      await expect(await subnetProxy._userCastedVotes(king1)).to.be.equals(5);
      await subnetProxy.connect(updater).setUserCastedVotes(king1, 77);
      await expect(await subnetProxy._userCastedVotes(king1)).to.be.equals(77);
    });
    it("should setBatchUserVotesToSubnet", async () => {
      await expect(
        await subnetProxy._userVotesToSubnet(queen2.address, 2),
      ).to.be.equals(2);
      await subnetProxy
        .connect(updater)
        .setBatchUserVotesToSubnet([king1, queen2], [1, 77], [1, 2]);
      await expect(
        await subnetProxy._userVotesToSubnet(queen2.address, 2),
      ).to.be.equals(77);
    });
    it("should setUpdater", async () => {
      await subnetProxy.setUpdater(newUpdater);
      await expect(await subnetProxy._updater()).to.be.equals(newUpdater);
    });
    it("should setUserVotesToSubnet", async () => {
      await expect(
        await subnetProxy._userVotesToSubnet(king1.address, 1),
      ).to.be.equals(1);
      await expect(
        subnetProxy.connect(updater).setUserVotesToSubnet(king1, 69, 1),
      ).to.be.revertedWith("You are not the authorized updater");
      await subnetProxy.connect(newUpdater).setUserVotesToSubnet(king1, 69, 1);
      await expect(
        await subnetProxy._userVotesToSubnet(king1.address, 1),
      ).to.be.equals(69);
    });
  });
});
