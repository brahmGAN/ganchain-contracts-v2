// const { ethers } = require("hardhat");
// const { expect } = require("chai");

// describe("Subnet", () => {
//   let owner;
//   let seller;
//   let buyer;
//   const uri =
//     "https://lavender-puny-mosquito-504.mypinata.cloud/ipfs/QmR3udFV7BDMVt1pUDpsg4Y7jdLFCdpC5VwV7BkT9gMKYJ";
//   before(async () => {
//     [owner, seller, buyer] = await ethers.getSigners();
//     nodeFactory = await ethers.getContractFactory("GanNode");
//     nodeProxy = await upgrades.deployProxy(nodeFactory, [], {
//       initializer: "initialize",
//       from: owner.address,
//     });
//   });

//   describe("Marketplace", () => {
//     it("Should mint node and seller should put a sell order and buyer completes the order", async () => {
//       //mint a node for seller
//       await nodeProxy.connect(owner).mintNode(seller, uri);
//       await expect(await nodeProxy.ownerOf(1)).to.be.equals(seller);
//       //set tier prices
//       await nodeProxy
//         .connect(owner)
//         .setTierPrice([
//           ethers.parseEther("1"),
//           ethers.parseEther("2"),
//           ethers.parseEther("3"),
//           ethers.parseEther("4"),
//         ]);
//       //set lock status
//       await nodeProxy.connect(owner).setLockStatus(0, true);
//       await nodeProxy.connect(owner).setLockStatus(1, true);
//       //sell nodes: Transfer to the contract in batch
//       await nodeProxy.connect(seller).sellNodes(1, [1], 3);
//       //buy nodes: Transfer to the buyer from the conract
//       await nodeProxy
//         .connect(buyer)
//         .buyNodes(1, 0, [1], { value: ethers.parseEther("4") });
//       await expect(await nodeProxy.ownerOf(1)).to.be.equals(buyer);
//     });
//   });
// });
