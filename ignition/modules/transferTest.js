const { ethers } = require("ethers");
require("dotenv").config();

async function sendETH() {
  console.log("My Transfer Test start:\n");
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const wallet = new ethers.Wallet(process.env.SENDER_PRIVATE_KEY, provider);

  //can receive: 0x76CE273F3e3Db7a8a28785c2996E02233fb657f0
  //can't receive: 0x63840B1f1BBb02595264ee6413B2Ded83b7f0c18

  const tx = await wallet.sendTransaction({
    to: "0x63840B1f1BBb02595264ee6413B2Ded83b7f0c18",
    value: ethers.parseEther("0.1"),
  });

  console.log("Transaction Hash:", tx.hash);
  await tx.wait();
  console.log("Done!");
}

sendETH().catch(console.error);
