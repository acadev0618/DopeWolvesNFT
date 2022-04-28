const hre = require("hardhat");
const fs = require('fs');

async function main() {
  // const NFTMarket = await hre.ethers.getContractFactory("NFTMarket");
  // const nftMarket = await NFTMarket.deploy();
  // await nftMarket.deployed();
  // console.log("nftMarket deployed to:", nftMarket.address);

  // const NFT = await hre.ethers.getContractFactory("NFT");
  // const nft = await NFT.deploy(nftMarket.address);
  // await nft.deployed();
  // console.log("nft deployed to:", nft.address);

  const accounts = await hre.ethers.getSigners();
  const account = accounts[0].address;
  console.log("owner address: ", account);

  const LoxarToken = await ethers.getContractFactory("LoxarToken")
  const lxtoken = await LoxarToken.deploy()
  await lxtoken.deployed()
  console.log("lxtoken deployed to:", lxtoken.address);

  const DopeWolvesNFT = await ethers.getContractFactory("DopeWolvesNFT");
  const dwNFT = await DopeWolvesNFT.deploy("DopeWolves", "DW", "https://img.tofunft.com/ipfs/QmVJByrWPjUJYuS2ia7JKfWwz6iuofZu6oktvFkT2sw6d3/");
  await dwNFT.deployed();
  console.log("dwNFT deployed to:", dwNFT.address);

  const DWNFTStaking = await ethers.getContractFactory("DWNFTStaking");
  const dwStaking = await DWNFTStaking.deploy(lxtoken.address, dwNFT.address);
  await dwStaking.deployed();
  console.log("dwStaking deployed to:", dwStaking.address);

  let config = `
  export const nftmarketaddress = "${dwStaking.address}"
  export const nftaddress = "${dwNFT.address}"
  `

  let data = JSON.stringify(config)
  fs.writeFileSync('config.js', JSON.parse(data))

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });