const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const shared_deployer = new ethers.Wallet(process.env.SHARED_DEPLOYER, provider);

  const shared_deployed_public = "0x898345e0b70D7fcC8e7227B444DEc90b1154DFa5";
  const mockUsdtFactory = await ethers.getContractFactory("MockUSDT");
  const mockUsdt = await mockUsdtFactory.deploy(shared_deployed_public);

  const usdtVaultFactory = await ethers.getContractFactory("USDTVault");
  const usdtVaultProxy = await upgrades.deployProxy(
    usdtVaultFactory,
    [mockUsdt.target],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    },
  );

  console.log("mock USDT deployed at:", mockUsdt.target);
  console.log("USDTVault deployed at:", usdtVaultProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
