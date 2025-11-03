const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {

  const fundsHandler = "0x4aba3419af9221c74ffc195ede5b09639e3109eb"; 
  const provider = new ethers.JsonRpcProvider(process.env.GPU_RPC);  
  const deployer = new ethers.Wallet(process.env.SHARED_DEPLOYER, provider);
  const creditsFactory = await ethers.getContractFactory("credits");
  const creditsProxy = await upgrades.deployProxy(
    creditsFactory,
    [fundsHandler],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    }
  );
  await creditsProxy.waitForDeployment();  
  console.log("Buy credits deployed at:", creditsProxy.target);
//   console.log("Lock status before:",+await creditsProxy._buyCredits());
//   await creditsProxy.connect(deployer).setLockStatus(true,1);
//   console.log("Lock status after:",await creditsProxy._buyCredits());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
