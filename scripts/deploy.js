const hre = require("hardhat");

async function main() {
    const contractFactory = await hre.ethers.getContractFactory("SocialMedia");
    const socialMedia = await contractFactory.deploy();

    console.log("Social media deployed to : " + socialMedia.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });