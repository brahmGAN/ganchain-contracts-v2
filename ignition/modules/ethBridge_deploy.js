const { ethers } = require("hardhat");
require('dotenv').config();

async function main()
{
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY,provider);

  const relayer_shivam = "0x68da33B8FF8c61cdB427FaA25De3304a2673d302";

  const gpuTokenEthFactory = await ethers.getContractFactory("GpuTokenEth"); 
  const gpuTokenEthProxy = await upgrades.deployProxy(
    gpuTokenEthFactory,
    [
        ethers.parseEther("1000000")
    ],
    { initializer: "initialize",
        gasPrice: ethers.parseUnits("30", "gwei"),
// timeout: 180000, // 3 minutes in milliseconds
// pollingInterval: 5000
     }
  );

//   const tx1 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 0);
//   //await tx1.wait();

  console.log("GPU token on sepolia deployed at:", gpuTokenEthProxy.target);

  const ethBridgeFactory = await ethers.getContractFactory("GpuEthBridge"); 
  const ethBridgeProxy = await upgrades.deployProxy(
    ethBridgeFactory,
    [
        gpuTokenEthProxy.target,
        relayer_shivam
    ],
    { initializer: "initialize",
        gasPrice: ethers.parseUnits("30", "gwei"),
// timeout: 180000, // 3 minutes in milliseconds
// pollingInterval: 5000
     }
  );

   const tx1 = await ethBridgeProxy.connect(owner).setLockStatus(true, 0);
//   //await tx1.wait();

  console.log("Ethereum bridge on sepolia deployed at:", ethBridgeProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});