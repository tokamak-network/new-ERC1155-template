const { ethers } = require("hardhat");
require('dotenv').config();
// command to run: "source .env"
// command to run: "npx hardhat run scripts/zkSync/5.Initialization.js --network l2"

async function main() {
  const [deployer] = await ethers.getSigners();

  
  // Fetch environment variables
  const assetFactoryAddress = process.env.ASSET_FACTORY;

  const assetFactoryProxyAddress = process.env.ASSET_FACTORY_PROXY;
  const treasuryAddress = process.env.TREASURY;
  const treasuryProxyAddress = process.env.TREASURY_PROXY;

  
  if (!assetFactoryAddress || !assetFactoryProxyAddress|| !treasuryAddress || !treasuryProxyAddress) {
    throw new Error("Environment variables NFT_FACTORY, NFT_FACTORY_PROXY, TREASURY and TREASURY_PROXY must be set");
  }
    
  // Get contract instances
  const AssetFactory = await ethers.getContractAt("AssetFactory", assetFactoryProxyAddress);
  const Treasury = await ethers.getContractAt("Treasury", treasuryProxyAddress);
  
  // ---------------------------- AssetFactoryProxy INITIALIZATION ---------------------------------

  const wstonValues = [
    10000000000000000000000000000n,
    20000000000000000000000000000n,
    30000000000000000000000000000n,
    40000000000000000000000000000n
  ];
  const uris = ["", "", "", ""]
  // Initialize AssetFactory with newly created contract addresses
  const initializeTx = await AssetFactory.initialize(
    deployer.address,
    process.env.ZKSYNC_SEPOLIA_WSTON_ADDRESS,
    treasuryProxyAddress,
    wstonValues,
    uris,
    { gasLimit: 10000000 }
  );
  await initializeTx.wait();
  console.log("NFTFactoryProxy initialized");
  
  // ---------------------------- TREASURYPROXY INITIALIZATION ---------------------------------
  // Attach the Treasury interface to the TreasuryProxy contract address
  console.log("treasury initialization...");
  // Call the Treasury initialize function
  const tx2 = await Treasury.initialize(
    process.env.ZKSYNC_SEPOLIA_WSTON_ADDRESS, // l2wston
    nftFactoryProxyAddress
  );
  await tx2.wait();
  console.log("TreasuryProxy initialized");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
