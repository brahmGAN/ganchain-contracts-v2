const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.GPU_RPC);
  const shared_deployer = new ethers.Wallet(process.env.SHARED_DEPLOYER, provider);

  const gpuVaultFactory = await ethers.getContractFactory("GPUVault");
  const gpuVaultProxy = await upgrades.deployProxy(
    gpuVaultFactory,
    [],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    },
  );

  console.log("GPUVault deployed at:", gpuVaultProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
