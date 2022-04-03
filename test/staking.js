/* test/sample-test.js */
describe("DopeWolves Staking", function() {
    it("Hunting Season Test Scinario", async function() {
      /* deploy the marketplace */
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
    
      const [_, buyerAddress] = await ethers.getSigners();

    const accounts = await hre.ethers.getSigners();
    const account = accounts[0].address;
    console.log("owner address: ", account);


    const balanceLxtoken = await lxtoken.balanceOf(account);
    console.log("loxer balance: ", balanceLxtoken);

    var balanceDWToke = await dwNFT.balanceOf(account);
    console.log("dwNFT balance: ",balanceDWToke);

    const price = ethers.utils.parseUnits('1800', 'ether')

    await dwNFT.connect(buyerAddress).mint(account, 6, {value: price});

    balanceDWToke = await dwNFT.balanceOf(account);
    console.log("updated dwNFT balance: ",balanceDWToke);


    const tokensOfOwner = await dwNFT.walletOfOwner(account);
    console.log(" tokens of Owner", tokensOfOwner);

    for (let token in tokensOfOwner)
    {
        console.log("token ID: ", tokensOfOwner[token], " approved to ", await dwNFT.ownerOf(tokensOfOwner[token]));
        await dwNFT.approve(dwStaking.address, tokensOfOwner[token]);
    }

    await dwStaking.startHuntingSeason();
    console.log(" Starting Hunting Season.")


    console.log(" set rarity level for wolves");
    await dwStaking.setRarityLevel(11, 1);
    await dwStaking.setRarityLevel(12, 1);
    await dwStaking.setRarityLevel(13, 1);
    await dwStaking.setRarityLevel(14, 1);
    await dwStaking.setRarityLevel(15, 1);

    await dwStaking.setRarityLevel(16, 2);
    await dwStaking.setRarityLevel(17, 2);
    await dwStaking.setRarityLevel(18, 2);

    await dwStaking.setRarityLevel(19, 3);
    await dwStaking.setRarityLevel(20, 3);

    await dwStaking.setRarityLevel(21, 4);


    for (let token in tokensOfOwner)
    {
        console.log("staked token ID: ", tokensOfOwner[token]);
        await dwStaking.stake(tokensOfOwner[token]);
    }

    console.log("getBalanceRewardToken: ", dwStaking.getBalanceRewardToken());
    // console.log(" reward amount: ", await dwStaking.calculateRewardAmount(account));

    await dwStaking.timeOutHuntingSeason();
    console.log("timeout hunting season !!!")
    })
  })