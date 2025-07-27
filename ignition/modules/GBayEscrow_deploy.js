const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {

  const escrowHandler = "0xE54aae92cb417aa2B17a359957D6BbF4661e5151";

  const GBayEscrowFactory = await ethers.getContractFactory(
    "GBayEscrow"
  );
  const GBayEscrowProxy = await upgrades.deployProxy(
    GBayEscrowFactory,
    [escrowHandler],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    }
  );

  console.log("GBayEscrow deployed at:", GBayEscrowProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});