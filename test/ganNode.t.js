const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("GANNode ERC721 Enumerable", () => {
  let owner;
  let user1;
  let user2;
  let user3;
  let ganNode;

  before(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners();
    const GANNodeFactory = await ethers.getContractFactory("GANNode");
    ganNode = await GANNodeFactory.deploy();
  });

  describe("ERC721 Enumerable functionality", () => {
    it("Should mint NFTs to 3 users in jumbled order and verify tokensOfOwner", async () => {
      const uri = "https://example.com/metadata/";

      // Mint NFTs in jumbled order (using owner account)
      await ganNode.connect(owner).mintNode(user1.address, uri); // Token ID: 1
      await ganNode.connect(owner).mintNode(user3.address, uri); // Token ID: 2
      await ganNode.connect(owner).mintNode(user2.address, uri); // Token ID: 3
      await ganNode.connect(owner).mintNode(user1.address, uri); // Token ID: 4
      await ganNode.connect(owner).mintNode(user2.address, uri); // Token ID: 5
      await ganNode.connect(owner).mintNode(user3.address, uri); // Token ID: 6
      await ganNode.connect(owner).mintNode(user1.address, uri); // Token ID: 7

      // Get tokens for each user
      const user1Tokens = await ganNode.tokensOfOwner(user1.address);
      const user2Tokens = await ganNode.tokensOfOwner(user2.address);
      const user3Tokens = await ganNode.tokensOfOwner(user3.address);

      // Log results
      console.log(
        "User1 tokens:",
        user1Tokens.map((t) => t.toString())
      );
      console.log(
        "User2 tokens:",
        user2Tokens.map((t) => t.toString())
      );
      console.log(
        "User3 tokens:",
        user3Tokens.map((t) => t.toString())
      );

      // Verify correct token counts
      expect(user1Tokens.length).to.equal(3);
      expect(user2Tokens.length).to.equal(2);
      expect(user3Tokens.length).to.equal(2);

      // Verify correct token IDs by position and inclusion
      expect(user1Tokens).to.include(1n);
      expect(user1Tokens).to.include(4n);
      expect(user1Tokens).to.include(7n);
      expect(user2Tokens).to.include(3n);
      expect(user2Tokens).to.include(5n);
      expect(user3Tokens).to.include(2n);
      expect(user3Tokens).to.include(6n);

      // Verify exact token IDs by position
      expect(user1Tokens[0]).to.equal(1n);
      expect(user1Tokens[1]).to.equal(4n);
      expect(user1Tokens[2]).to.equal(7n);
      expect(user2Tokens[0]).to.equal(3n);
      expect(user2Tokens[1]).to.equal(5n);
      expect(user3Tokens[0]).to.equal(2n);
      expect(user3Tokens[1]).to.equal(6n);
    });
  });
});
