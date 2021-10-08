const hre = require("hardhat");

async function main() {

  const ERC0 = await hre.ethers.getContractFactory("ERC0");
  const erc20 = await ERC0.deploy(1000000000000000000);

  await erc20.deployed();

  console.log("ERC20 deployed to:", erc20.address);


  const ERC721 = await hre.ethers.getContractFactory("ERC721");
  const erc721 = await ERC721.deploy();

  await erc721.deployed();

  console.log("ERC721 deployed to:", erc721.address);


  const DSocailMedia = await hre.ethers.getContractFactory("DSocailMedia");
  const dSocailMedia = await DSocailMedia.deploy();

  await dSocailMedia.deployed();



  console.log("Greeter deployed to:", dSocailMedia.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
