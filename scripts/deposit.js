// scripts/checkTotalDeposited.js
const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0x11733F474Ae0e868D511d48309d3B35846f47415";
  
  const gpuVault = await ethers.getContractAt("GPUVault", contractAddress);
  
  const totalDeposited = await gpuVault.totalDeposited();
  const balance = await ethers.provider.getBalance(contractAddress);
  
  console.log(`Total Deposited: ${ethers.formatEther(totalDeposited)} ETH`);
  console.log(`Contract Balance: ${ethers.formatEther(balance)} ETH`);
}

main().catch(console.error);