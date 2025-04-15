const { ethers } = require("hardhat");
require('dotenv').config();

async function main()
{
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY,provider);

  let updater = "0x71C1f0B4E829868626c5c16ADb09166190e7B4Bf";

  const subnetFactory = await ethers.getContractFactory("Subnet"); 
  const subnetProxy = await upgrades.deployProxy(
    subnetFactory,
    [
      updater
    ],
    { initializer: "initialize",
        gasPrice: ethers.parseUnits("30", "gwei"),
// timeout: 180000, // 3 minutes in milliseconds
// pollingInterval: 5000
     }
  );

  const tx1 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 0);
  //await tx1.wait();
  const tx2 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 1);
  //await tx2.wait();
  const tx3 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 2);
  //await tx3.wait();
  const tx4 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 3);
  //await tx4.wait();
  const tx5 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 4);
  //await tx5.wait();

  const tx6 = await subnetProxy.connect(owner).setUserFunctionStatus(true, 5);
  //await tx5.wait();

  console.log("Subnet deployed at:", subnetProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});