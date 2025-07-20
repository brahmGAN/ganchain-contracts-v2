const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);

  const gpuTokenEthFactory = await ethers.getContractFactory("GpuTokenEth");
  const gpuTokenEthProxy = await upgrades.deployProxy(
    gpuTokenEthFactory,
    [ethers.parseEther("1000000")],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    }
  );

  //   const tx1 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 0);
  //   //await tx1.wait();

  console.log("Subnet deployed at:", gpuTokenEthProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
