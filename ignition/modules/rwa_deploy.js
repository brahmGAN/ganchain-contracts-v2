const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const shared_deployer = "0x898345e0b70D7fcC8e7227B444DEc90b1154DFa5";
  const refundHandler = "0x898345e0b70D7fcC8e7227B444DEc90b1154DFa5";
  const dealExecutor = "0x898345e0b70D7fcC8e7227B444DEc90b1154DFa5";
  const dealAmount = 1_000_000n * 10n ** 6n;

  const mockUsdtFactory = await ethers.getContractFactory("MockUSDT");
  const mockUsdt = await mockUsdtFactory.deploy(shared_deployer);

  const rwaFactory = await ethers.getContractFactory("rwa");
  const rwaProxy = await upgrades.deployProxy(
    rwaFactory,
    [mockUsdt.target, refundHandler, dealExecutor, dealAmount],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
    }
  );
  //write a function to mint 1 billion mock usdt to shared_deployer
  const mintMockUsdt = async () => {
    const mintTx = await mockUsdt.mint(shared_deployer, 1_000_000_000n * 10n ** 6n);
    await mintTx.wait();
  };
  await mintMockUsdt();
  console.log("mock USDT deployed at:", mockUsdt.target);
  console.log("rwa deployed at:", rwaProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
