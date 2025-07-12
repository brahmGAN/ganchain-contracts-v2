const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
//   const provider = new ethers.JsonRpcProvider(process.env.GPU_RPC);
//   const shared_deployer = new ethers.Wallet(process.env.SHARED_DEPLOYER, provider);

  const GANNodeFactory = await ethers.getContractFactory("GANNode");
  const GANNode = await GANNodeFactory.deploy();

  const orderBookHandlerRandall = "0x9aA81e452e764791B72dc3aE97F8Ffb32324E9A8";

  const GANNodeVaultVaultFactory = await ethers.getContractFactory("GANNodeVault");
  const GANNodeVaultProxy = await upgrades.deployProxy(
    GANNodeVaultVaultFactory,
    [GANNode.target,orderBookHandlerRandall],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    },
  );

  console.log("GANNode deployed at:", GANNode.target);
  console.log("GANNodeVault deployed at:", GANNodeVaultProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
