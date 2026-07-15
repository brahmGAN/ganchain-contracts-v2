const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const validatorRewardsUpdater = "0x279b553bA7B4c7181845144f618c953bF0c30970";

  const v1ValidatorRewardsFactory = await ethers.getContractFactory("v1ValidatorRewards");
  const v1ValidatorRewardsProxy = await upgrades.deployProxy(
    v1ValidatorRewardsFactory,
    [validatorRewardsUpdater],
    {
      initializer: "initialize",
      gasPrice: ethers.parseUnits("30", "gwei"),
      // timeout: 180000, // 3 minutes in milliseconds
      // pollingInterval: 5000
    }
  );

  console.log("v1ValidatorRewards deployed at:", v1ValidatorRewardsProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
