const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
    // Contract address (replace with your deployed contract address)
    const contractAddress = "YOUR_CONTRACT_ADDRESS_HERE";
    
    // Get provider and owner wallet
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    const owner = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);
    
    // Get the contract instance
    const gpuToken = await ethers.getContractAt("GpuTokenEth", contractAddress, owner);
    
    console.log("Pausing transfers...");
    
    // Call pauseTransfers function
    const tx = await gpuToken.pauseTransfers();
    await tx.wait();
    
    console.log("✅ Transfers paused successfully!");
    console.log("Transaction hash:", tx.hash);
}

main().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});