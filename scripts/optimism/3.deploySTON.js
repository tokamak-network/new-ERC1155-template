const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/optimism/3.deploySTON.js --network l2"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await deployer.getBalance();
    console.log("Account balance:", ethers.utils.formatEther(balance));

    // ------------------------ NFTFACTORY INSTANCE ---------------------------------

    const AssetFactory = await ethers.getContractFactory("AssetFactory");
    const assetFactory = await AssetFactory.deploy();
    await assetFactory.deployed();
    console.log("AssetFactory deployed to:", assetFactory.address);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // ------------------------ ASSETFACTORY PROXY ---------------------------------

    const AssetFactoryProxy = await ethers.getContractFactory("AssetFactoryProxy");
    const assetFactoryProxy = await AssetFactoryProxy.deploy();
    await assetFactoryProxy.deployed();
    console.log("AssetFactoryProxy deployed to:", assetFactoryProxy.address);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    const upgradeAssetFactoryTo = await assetFactoryProxy.upgradeTo(assetFactory.address);
    await upgradeAssetFactoryTo.wait();
    console.log("AssetFactoryProxy upgraded to AssetFactory");

    // ------------------------ TREASURY INSTANCE ---------------------------------

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy();
    await treasury.deployed();
    console.log("Treasury deployed to:", treasury.address);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // ------------------------ TREASURY PROXY INSTANCE ---------------------------------

    const TreasuryProxy = await ethers.getContractFactory("TreasuryProxy");
    const treasuryProxy = await TreasuryProxy.deploy();
    await treasuryProxy.deployed(); // Ensure deployment is complete
    console.log("TreasuryProxy deployed to:", treasuryProxy.address);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // Set the first index to the GemFactory contract
    const upgradeTreasuryTo = await treasuryProxy.upgradeTo(treasury.address);
    await upgradeTreasuryTo.wait();
    console.log("TreasuryProxy upgraded to Treasury");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
