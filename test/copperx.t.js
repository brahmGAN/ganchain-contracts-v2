// const { ethers } = require("hardhat");
// const { expect } = require("chai");

// describe("CopperX", () => {
//   let owner;
//   let fundsHandler;
//   let user1;
//   let copperxProxy;

//   before(async () => {
//     [owner, user1, fundsHandler] = await ethers.getSigners();

//     copperxFactory = await ethers.getContractFactory("CopperxGPU");
//     copperxProxy = await upgrades.deployProxy(
//         copperxFactory,
//       [fundsHandler.address],
//       {
//         initializer: "initialize",
//         from: owner.address,
//       }
//     );

//     // Send some ETH to contract for testing
//     await owner.sendTransaction({
//       to: copperxProxy.target,
//       value: ethers.parseEther("10")
//     });
//   });

//   describe("releaseGpu::", () => {
//     it("Should revert when release is not enabled", async () => {
//       await expect(
//         copperxProxy.connect(fundsHandler).releaseGpu(ethers.parseEther("1"), user1.address)
//       ).to.be.revertedWithCustomError(copperxProxy, "notYetAvailable");
//     });

//     it("Should revert when called by non-fundsHandler", async () => {
//       await copperxProxy.connect(owner).setLockStatus(true, 0);
//       await expect(
//         copperxProxy.connect(user1).releaseGpu(ethers.parseEther("1"), user1.address)
//       ).to.be.revertedWithCustomError(copperxProxy, "UnauthorizedFundsHandler");
//     });

//     it("Should revert when amount exceeds contract balance", async () => {
//       await expect(
//         copperxProxy.connect(fundsHandler).releaseGpu(ethers.parseEther("100"), user1.address)
//       ).to.be.revertedWithCustomError(copperxProxy, "inSufficientBalanceInContract");
//     });

//     it("Should successfully release GPU tokens", async () => {
//       const amount = ethers.parseEther("1");
//       const initialBalance = await ethers.provider.getBalance(user1.address);

//       await expect(
//         copperxProxy.connect(fundsHandler).releaseGpu(amount, user1.address)
//       ).to.emit(copperxProxy, "releasedGpu")
//       .withArgs(user1.address, await ethers.provider.getBlockNumber(), amount);

//       const finalBalance = await ethers.provider.getBalance(user1.address);
//       expect(finalBalance).to.equal(initialBalance + amount);

//       // Check released amount tracking
//       expect(await copperxProxy._releasedAmount(user1.address)).to.equal(amount);
//       expect(await copperxProxy._totalReleasedAmount()).to.equal(amount);
//     });
//   });
// });
