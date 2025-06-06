const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  // Contract address (replace with your deployed contract address)
  const contractAddress = "0xB192A74fA21ed7f5C1A6f81D95F3C76665271ba1";

  // Get provider and owner wallet
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);

  // Get the contract instance
  const gpuToken = await ethers.getContractAt(
    "GpuTokenEth",
    contractAddress,
    owner,
  );

  console.log("Pausing transfers...");

  const aryan = "0xDb912955Ea48Ed428978980c70d76272656B5e4d";

  // Call pauseTransfers function
  const tx = await gpuToken.mint(aryan, ethers.parseEther("20000"));
  // const tx = await gpuToken.pauseTransfers();
  //const tx = await gpuToken.unpauseTransfers();
  await tx.wait();

  console.log("✅ Transfers paused successfully!");
  console.log("Transaction hash:", tx.hash);
}

main().catch((error) => {
  console.error("❌ Error:", error);
  process.exitCode = 1;
});
