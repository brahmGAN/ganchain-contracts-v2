const { ethers, upgrades } = require("hardhat");
const { expect, use } = require("chai");

describe("GBay", () => {
  let owner;
  let escrowHandler;
  let user1;
  let user2;
  let GBayFactory;
  let GBayProxy;
  
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
    
    it("Should let users create order", async () => {
        // Get initial order ID
        const initialOrderId = await GBayProxy._orderId();
        
        // Amount in wei (1 ETH = 1000000000000000000 wei) 
        const orderAmount = ethers.parseEther("1.5"); // 1.5 ETH in wei
        
        // Create order and expect event emission
        await expect(GBayProxy.connect(user1).createOrder(orderAmount))
            .to.emit(GBayProxy, "orderCreated")
            .withArgs(user1.address, initialOrderId, orderAmount);
        
        // Verify order details
        await expect(await GBayProxy._orderAmount(initialOrderId)).to.equals(orderAmount);
        await expect(await GBayProxy._seller(initialOrderId)).to.equals(user1.address);
        await expect(await GBayProxy._orderStatus(initialOrderId)).to.equals(0); // orderCreated = 0
        
        // Verify order ID has been incremented
        await expect(await GBayProxy._orderId()).to.equals(initialOrderId + 1n);
    });
    
    it("Should fail to create order when _createOrder is false", async () => {
        // Set _createOrder to false
        await GBayProxy.connect(owner).setLockStatus(false, 0);
        
        const orderAmount = ethers.parseEther("1.0");
        
        // Should revert with notYetAvailable error
        await expect(
            GBayProxy.connect(user2).createOrder(orderAmount)
        ).to.be.revertedWithCustomError(GBayProxy, "notYetAvailable");
        
        // Re-enable _createOrder for other tests
        await GBayProxy.connect(owner).setLockStatus(true, 0);
    });
    
    it("Should allow multiple users to create orders", async () => {
        const user1Amount = ethers.parseEther("2.0");
        const user2Amount = ethers.parseEther("0.5");
        
        // Get current order ID
        const currentOrderId = await GBayProxy._orderId();
        
        // User1 creates order
        await GBayProxy.connect(user1).createOrder(user1Amount);
        
        // User2 creates order
        await GBayProxy.connect(user2).createOrder(user2Amount);
        
        // Verify both orders were created correctly
        expect(await GBayProxy._orderAmount(currentOrderId)).to.equal(user1Amount);
        expect(await GBayProxy._seller(currentOrderId)).to.equal(user1.address);
        
        expect(await GBayProxy._orderAmount(currentOrderId + 1n)).to.equal(user2Amount);
        expect(await GBayProxy._seller(currentOrderId + 1n)).to.equal(user2.address);
        
        // Verify order ID has been incremented twice
        expect(await GBayProxy._orderId()).to.equal(currentOrderId + 2n);
    });
  });
});
