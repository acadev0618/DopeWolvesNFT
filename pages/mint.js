import { useState } from "react";
import { ethers } from "ethers";
import { useRouter } from "next/router";
import Web3Modal from "web3modal";

import { nftaddress} from "./config";

import DWNFT from '../contracts_abi/DopeWolvesNFT.json';

export default function MintNFT() {
  const [mintAmount, setMintAmount] = useState();

  const router = useRouter();

  async function mintDopeWolves() {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner();
    const address = await signer.getAddress();
    const network = await provider.getNetwork();

    console.log("address:", address, "network", network);

    const tokenContract = new ethers.Contract(nftaddress, DWNFT.abi, signer);
    
    const cost = mintAmount * 299;
    
    const price = ethers.utils.parseUnits(cost.toString(), 'ether');

    console.log("amount: ", mintAmount, "price:", cost);

    let transaction = await tokenContract.mint(address, mintAmount, {value: price});

    await transaction.wait();
    router.push("/");
  }
  
  return (
    <div className="flex justify-center">
      <div className="w-1/2 flex flex-col pb-12">
        <input
          placeholder="Mint Amount"
          className="mt-8 border rounded p-4"
          onChange={(e) =>
            setMintAmount(e.target.value)
          }
        />

        <button
          onClick={mintDopeWolves}
          className="font-bold mt-4 bg-pink-500 text-white rounded p-4 shadow-lg"
        >
          MINT DopeWolves
        </button>
      </div>
    </div>
  );
}
