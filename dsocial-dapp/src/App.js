import { useState } from 'react';
import {ethers} from 'ethers';
import './App.css';

const ipfsClient = require('ipfs-http-client')
const ipfs = ipfsClient.create({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' });

function App() {

  async function requestAccount(){
    await window.ethereum.request({ method: 'eth_requestAccounts' });//Helps user to connect one of their account of metamask if they are already not connected

  }

  
  return (
    <div className="App">
 
    </div>
  );
}

export default App;