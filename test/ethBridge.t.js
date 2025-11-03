// const { ethers } = require("hardhat");
// const { expect, use } = require("chai");

// describe("Bridge:", () => {
//   let owner;
//   let relayer1;
//   let relayer2;
//   let relayer3;
//   let user1;
//   let user2;
//   before(async () => {
//     [owner, relayer1, relayer2, relayer3, user1, user2] =
//       await ethers.getSigners();

//     gpuTokenFactory = await ethers.getContractFactory("GpuTokenEth");
//     gpuTokenProxy = await gpuTokenFactory.deploy(ethers.parseEther("1000000"));

//     ethBridgeFactory = await ethers.getContractFactory("GpuEthBridge");
//     ethBridgeProxy = await upgrades.deployProxy(
//       ethBridgeFactory,
//       [gpuTokenProxy.target, relayer1.address],
//       {
//         initializer: "initialize",
//         from: owner.address,
//       }
//     );

//     GanBridgeFactory = await ethers.getContractFactory("GanChainBridge");
//     ganBridgeProxy = await upgrades.deployProxy(
//       GanBridgeFactory,
//       [relayer1.address],
//       {
//         initializer: "initialize",
//         from: owner.address,
//       }
//     );
//   });

//   describe("Switch on all user callable functions", () => {
//     it("Should switch on every user functions", async () => {
//       await expect(await ganBridgeProxy._lockGpu()).to.be.equals(false);
//       await expect(await ethBridgeProxy._lockGpu()).to.be.equals(false);
//       await ganBridgeProxy.connect(owner).setLockStatus(true, 0);
//       await ethBridgeProxy.connect(owner).setLockStatus(true, 0);
//       await expect(await ganBridgeProxy._lockGpu()).to.be.equals(true);
//       await expect(await ethBridgeProxy._lockGpu()).to.be.equals(true);
//     });
//   });

//   describe("check relayers", () => {
//     it("Should set relayer2 and 3", async () => {
//       await expect(
//         await ganBridgeProxy._isRelayer(relayer2.address)
//       ).to.be.equals(false);
//       await expect(
//         await ethBridgeProxy._isRelayer(relayer3.address)
//       ).to.be.equals(false);
//       await ganBridgeProxy
//         .connect(owner)
//         .setRelayers([relayer2.address, relayer3.address], [true, true]);
//       await ethBridgeProxy
//         .connect(owner)
//         .setRelayers([relayer2.address, relayer3.address], [true, true]);
//       await expect(
//         await ganBridgeProxy._isRelayer(relayer2.address)
//       ).to.be.equals(true);
//       await expect(
//         await ethBridgeProxy._isRelayer(relayer3.address)
//       ).to.be.equals(true);
//       await expect(
//         await ganBridgeProxy._isRelayer(relayer1.address)
//       ).to.be.equals(true);
//     });
//   });

//   describe("Make the swap from GAN chain -> Ethereum", () => {
//     it("Should let users lock GPU on ganchain", async () => {
//       await expect(
//         await ethers.provider.getBalance(await ganBridgeProxy.getAddress())
//       ).to.be.equals(ethers.parseEther("0"));
//       await ganBridgeProxy.connect(user1).lockGpu(ethers.parseEther("10"), 1, {
//         value: ethers.parseEther("10"),
//       });
//       await expect(
//         await ethers.provider.getBalance(await ganBridgeProxy.getAddress())
//       ).to.be.equals(ethers.parseEther("10"));
//       await expect(
//         await ganBridgeProxy._totalLockedAmount(user1.address)
//       ).to.be.equals(ethers.parseEther("10"));
//       await expect(await ganBridgeProxy._lockedUser(0)).to.be.equals(
//         user1.address
//       );
//     });

//     it("Should release GPU to user-1 on Ethereum", async () => {
//       await gpuTokenProxy
//         .connect(owner)
//         .transfer(ethBridgeProxy.target, ethers.parseEther("500000"));
//       await expect(
//         await gpuTokenProxy.balanceOf(ethBridgeProxy.target)
//       ).to.equal(ethers.parseEther("500000"));
//       await expect(await gpuTokenProxy.balanceOf(user1)).to.equal(
//         ethers.parseEther("0")
//       );
//       await ethBridgeProxy
//         .connect(relayer1)
//         .releaseGpu(ethers.parseEther("10"), user1);
//       await expect(await gpuTokenProxy.balanceOf(user1)).to.equal(
//         ethers.parseEther("10")
//       );
//       await expect(
//         await ethBridgeProxy._totalReleasedAmount(user1.address)
//       ).to.be.equals(ethers.parseEther("10"));
//       console.log(
//         "TotalReleasedAmount: " +
//           (await ethBridgeProxy._totalReleasedAmount(user1.address))
//       );
//       console.log(
//         "TotalReleasedAmount: " +
//           (await ethBridgeProxy._totalReleasedAmount(user2.address))
//       );
//       console.log("releaseID: " + (await ethBridgeProxy._releaseId()));
//       await expect(await ethBridgeProxy._releasedUser(0)).to.be.equals(
//         user1.address
//       );
//     });
//   });

//   describe("Make the swap from Ethereum -> GAN chain ", () => {
//     it("Should let users lock GPU on Ethereum", async () => {
//       await expect(
//         await gpuTokenProxy.balanceOf(ethBridgeProxy.target)
//       ).to.equal(ethers.parseEther("499990"));
//       await gpuTokenProxy
//         .connect(owner)
//         .transfer(user2, ethers.parseEther("69"));
//       await gpuTokenProxy
//         .connect(user2)
//         .approve(ethBridgeProxy.target, ethers.parseEther("69"));
//       await ethBridgeProxy.connect(user2).lockGpu(ethers.parseEther("69"));
//       await expect(
//         await gpuTokenProxy.balanceOf(ethBridgeProxy.target)
//       ).to.equal(ethers.parseEther("500059"));
//       await expect(
//         await ethBridgeProxy._totalLockedAmount(user2.address)
//       ).to.be.equals(ethers.parseEther("69"));
//       await expect(await ethBridgeProxy._lockedUser(0)).to.be.equals(
//         user2.address
//       );
//     });

//     it("Should release GPU to user-1 on Ethereum", async () => {
//       await ganBridgeProxy.connect(user1).lockGpu(ethers.parseEther("100"), 1, {
//         value: ethers.parseEther("100"),
//       });
//       await expect(
//         await ethers.provider.getBalance(await ganBridgeProxy.getAddress())
//       ).to.be.equals(ethers.parseEther("110"));
//       console.log(
//         "user 2 balance: " + (await ethers.provider.getBalance(user2.address))
//       );
//       await expect(await ethers.provider.getBalance(user2.address)).to.equal(
//         ethers.parseEther("9999.999797164032875002")
//       );
//       console.log(
//         "user2 balance:" + (await ethers.provider.getBalance(user2.address))
//       );
//       await ganBridgeProxy
//         .connect(relayer2)
//         .releaseGpu(ethers.parseEther("69"), user2);
//       await expect(await ethers.provider.getBalance(user2.address)).to.equal(
//         ethers.parseEther("10068.999797164032875002")
//       );
//       await expect(
//         await ganBridgeProxy._totalReleasedAmount(user2.address)
//       ).to.be.equals(ethers.parseEther("69"));
//       await expect(await ganBridgeProxy._releasedUser(0)).to.be.equals(
//         user2.address
//       );
//     });
//   });
// });
