/* pages/index.js */
import { ethers } from "ethers";
import { useEffect, useState } from "react";
import axios from "axios";
import Web3Modal from "web3modal";

import { nftaddress, nftmarketaddress } from "../config";

import DWNFT from '../contracts_abi/DopeWolvesNFT.json';
import DWNFTStaking from '../contracts_abi/DWNFTStaking.json';


export default function Home() {
  const [nfts, setNfts] = useState([]);
  const [stakedNFTs, setStakedNFTs] = useState([]);
  const [loadingState, setLoadingState] = useState("not-loaded");
  const [huntingLabel, sethuntingLabel] = useState("Start H. Season");
  const [huntingState, sethuntingState] = useState(false);
  const [admin, setAdmin] = useState(false);
  
  useEffect(() => {
    loadNFTs();
  }, []);
  async function loadNFTs() {
    const web3Modal = new Web3Modal({
      network: "mainnet",
      cacheProvider: true,
    });
    /* create a generic provider and query for unsold market items */
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    const signer = provider.getSigner();
    const address = await signer.getAddress();
    const tokenContract = new ethers.Contract(nftaddress, DWNFT.abi, provider);

    const stakecontract = new ethers.Contract(nftmarketaddress, DWNFTStaking.abi, signer);
    const isAdmin = await stakecontract.isAdmin();
    setAdmin(isAdmin);

    const hunting = await stakecontract.isHuntingSeason();
    console.log("hunting ", hunting);
    sethuntingState(hunting);
    if (hunting)
      sethuntingLabel("Stop H. Season");
    else
      sethuntingLabel("Start H. Season");

    const data = await tokenContract.walletOfOwner(address);
    const stakedData = await stakecontract.getStakedTokens(address);
    console.log(stakedData);

    /*
     *  map over items returned from smart contract and format
     *  them as well as fetch their token metadata
     */
    // const items  = {};
    const items = await Promise.all(
      data.map(async (i) => {
        const tokenUri = await tokenContract.tokenURI(i.toNumber());
        const meta = await axios.get(tokenUri);
        let imageurl = meta.data.image.replace("ipfs://", "https://img.tofunft.com/ipfs/");
        console.log(imageurl);

        let item = {
          tokenId: i.toNumber(),
          image: imageurl,
          name: meta.data.name,
          description: meta.data.description,
        };
        return item;
      })
    );

    setNfts(items);

    const stakedItems = await Promise.all(
      stakedData.map(async (i) => {
        const tokenUri = await tokenContract.tokenURI(i.toNumber());
        const meta = await axios.get(tokenUri);
        let imageurl = meta.data.image.replace("ipfs://", "https://img.tofunft.com/ipfs/");
        console.log(imageurl);

        let item = {
          tokenId: i.toNumber(),
          image: imageurl,
          name: meta.data.name,
          description: meta.data.description,
        };
        return item;
      })
    );
    setStakedNFTs(stakedItems);
    console.log("staked data ", stakedNFTs);
    
    setLoadingState("loaded");
  }
  async function stakeNft(nft) {
    /* needs the user to sign the transaction, so will use Web3Provider and sign it */
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner();

    const stakecontract = new ethers.Contract(nftmarketaddress, DWNFTStaking.abi, signer);
    const hunting = await stakecontract.isHuntingSeason();
    if (hunting == false) {
      alert("not hunting season.");
      loadNFTs();
      return;
    }

    const tokenContract = new ethers.Contract(nftaddress, DWNFT.abi, signer);    
    await tokenContract.approve(nftmarketaddress, nft.tokenId);

    const transaction = await stakecontract.stake(nft.tokenId);
    await transaction.wait();

    loadNFTs();
  }
  async function unStakeNft(nft) {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner();

    const stakecontract = new ethers.Contract(nftmarketaddress, DWNFTStaking.abi, signer);
    const hunting = await stakecontract.isHuntingSeason();
    if (hunting == false) {
      alert("not hunting season.");
      loadNFTs();
      return;
    }
    const transaction = await stakecontract.unstake(nft.tokenId);
    await transaction.wait();
    loadNFTs();
  }

  async function startStopHuntingSeason() {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner();

    const stakecontract = new ethers.Contract(nftmarketaddress, DWNFTStaking.abi, signer);
    let transaction;

    if (!huntingState){
      transaction = await stakecontract.startHuntingSeason();
      await transaction.wait();

      sethuntingLabel("Stop H. Season");
      sethuntingState(true);
      console.log(" Starting Hunting Season.");
    }
    else {
      transaction = await stakecontract.timeOutHuntingSeason();
      await transaction.wait();

      sethuntingLabel("Start H. Season");
      sethuntingState(false);
      console.log("timeout hunting season !!!");
    }
    loadNFTs();
  }

  if (loadingState === "loaded" && !nfts.length)
    return <h1 className="px-20 py-10 text-3xl">No items in marketplace</h1>;
  return (
    <div>
      {huntingState == true &&
      <h2 className="px-5 py-2 text-3xl text-center "> Now Hunting Season!
        {/* Wolves need to hunt to survive, HUNT SEASONS are frequent events where your wolves will
         go hunting, and come back later with your $ROSE reward. */}
         </h2>
      }
      {huntingState == false &&
       <h2 className="px-5 py-2 text-3xl text-center "> Not Hunting Season!
       {/* Wolves need to hunt to survive, HUNT SEASONS are frequent events where your wolves will
        go hunting, and come back later with your $ROSE reward. */}
        </h2>
      }
      <div className="flex justify-center">
       <div className="px-6" style={{ maxWidth: "1000px" }}>
       <h2 className="px-5 py-2 text-3xl"> My Dope Wolves ({nfts.length})
         </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {nfts.map((nft, i) => (
            <div key={i} className="border shadow rounded-xl overflow-hidden">
              <img src={nft.image} />
              <div className="p-4">
                <p style={{ height: "20px" }}
                  className="text-2xl text-yellow-50 font-semibold"
                > Name: 
                  {nft.name}
                </p>
              </div>
              {huntingState == true && 
              <div className="p-6 bg-black" >
                
                <button
                  className="w-full bg-red-500 text-white font-bold py-2 px-12 rounded"
                  onClick={() => { 
                    if (huntingState) stakeNft(nft)
                    else alert("Hunting Season don't started");
                  }}
                >
                  Stake
                </button>
              </div>
              }
            </div>
          ))}
        </div>
        <h2 className="px-5 py-2 text-3xl"> Staked My Dope Wolves ({stakedNFTs.length})
         </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {stakedNFTs.map((nft, i) => (
            <div key={i} className="border shadow rounded-xl overflow-hidden">
              <img src={nft.image} />
              <div className="p-4">
                <p style={{ height: "20px" }}
                  className="text-2xl text-yellow-50 font-semibold"
                > Name: 
                  {nft.name}
                </p>
              </div>
              {huntingState == true && 
              <div className="p-6 bg-black" >
                
                <button
                  className="w-full bg-red-500 text-white font-bold py-2 px-12 rounded"
                  onClick={() => { 
                    if (huntingState) unStakeNft(nft)
                    else alert("Hunting Season don't started");
                  }}
                >
                 UnStake
                </button>
              </div>
              }
            </div>
          ))}
        </div>

       </div>
       <div className="px-4">
         {admin == true &&
           <button
                  className="w-full bg-red-500 text-white font-bold py-2 px-12 rounded"
                  onClick={() => {
                    let msg = !huntingState ? "Are you sure you wish to start hunting season?": 
                    "Are you sure you wish to stop hunting season?";
                    if (window.confirm(msg))
                     startStopHuntingSeason()
                    }}
                >
                  {huntingLabel}
           </button>
           }
           <div>
                <br></br> <h2>Loyalty percent</h2>

                <h3> Common: 20% </h3>
                <h3> Uncommon: 20% </h3>
                <h3> Rare: 20% </h3>
                <h3> Epic: 20% </h3>
                <h3> Legendary: 10% </h3>

                {/* <ul style="text-align: left;color: #ffffff80;"> 
                    <li style="font-size: 13px !important; text-transform: capitalize !important;"><span>Common: 20%</span></li>
                    <li style="font-size: 13px !important; text-transform: capitalize !important;"><span>Uncommon: 20%</span></li>
                    <li style="font-size: 13px !important; text-transform: capitalize !important;"><span>Rare: 20%</span></li>
                    <li style="font-size: 13px !important; text-transform: capitalize !important;"><span>Legendary: 20%</span></li>

                </ul> */}
                
            </div>
        </div>
     </div>
     
    </div>
  );
}
