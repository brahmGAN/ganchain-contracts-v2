const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.GPU_RPC);
  const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);

  const relayer_shivam = "0x68da33B8FF8c61cdB427FaA25De3304a2673d302";

  const GANchainFactory = await ethers.getContractFactory("GanChainBridge");
  const GANchainEthProxy = await upgrades.deployProxy(
    GANchainFactory,
    [relayer_shivam],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    },
  );

  const tx1 = await GANchainEthProxy.connect(owner).setLockStatus(true, 0);
  //   //await tx1.wait();

  console.log("GAN Chain bridge deployed at:", GANchainEthProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
