.PHONY: test compile

compile:
	npx hardhat compile

test: 
	npx hardhat test 

deploy-sepolia: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/Subnet_deploy.js --network sepolia

deploy-gpu: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/Subnet_deploy.js --network gpu

deploy-gpuToken: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/GpuTokenEth_deploy.js --network sepolia



deploy-ganchainBridge: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/GANchainBridge_deploy.js --network gpu

deploy-ethBridge: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/ethBridge_deploy.js --network sepolia

deploy-gpuVault: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/GPUVault_deploy.js --network gpu

deploy-GANNodeVault: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/GANNodeVault_deploy.js --network gpu

deploy-usdtVault: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/USDTVault.js --network sepolia

clean: 
	npx hardhat clean

pretty: 
	npx prettier --write "**/*.js"

deploy-gbay: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/GBayEscrow_deploy.js --network gpu

deploy-copperx: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/copperx_deploy.js --network gpu

deploy-credits: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts-v2/ignition/modules/credits_deploy.js --network gpu