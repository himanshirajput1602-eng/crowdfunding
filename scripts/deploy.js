const hre = require("hardhat");

async function main() {
  console.log("Deploying CrowdfundingPlatform contract to Core Blockchain...");

  // Get the contract factory
  const CrowdfundingPlatform = await hre.ethers.getContractFactory("CrowdfundingPlatform");
  
  // Deploy the contract
  const crowdfundingPlatform = await CrowdfundingPlatform.deploy();
  
  // Wait for the contract to be deployed
  await crowdfundingPlatform.deployed();

  console.log("CrowdfundingPlatform deployed to:", crowdfundingPlatform.address);
  console.log("Transaction hash:", crowdfundingPlatform.deployTransaction.hash);
  console.log("Deployed on network:", hre.network.name);
  console.log("Chain ID:", hre.network.config.chainId);
  
  // Verify deployment by calling a view function
  const campaignCounter = await crowdfundingPlatform.campaignCounter();
  console.log("Initial campaign counter:", campaignCounter.toString());
  
  const platformOwner = await crowdfundingPlatform.platformOwner();
  console.log("Platform owner:", platformOwner);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });
