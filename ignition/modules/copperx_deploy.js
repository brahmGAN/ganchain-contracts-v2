const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {

  const fundsHandler = "0xB87Be23d7F869BC7E355c1af2F6b575B854f1BB4";

  const copperxFactory = await ethers.getContractFactory("CopperxGPU");
  const copperxProxy = await upgrades.deployProxy(
    copperxFactory,
    [fundsHandler],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    }
  );

  console.log("copperX deployed at:", copperxProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
