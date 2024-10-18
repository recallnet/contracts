/** @type import('hardhat/config').HardhatUserConfig */
require("hardhat-storage-layout-changes");
require("@nomicfoundation/hardhat-foundry");

const path = require("path");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.23",  
      },
      {
        version: "0.8.26",  
      }
    ],
  },
  paths: {
    sources: "./src", 
    storageLayouts: ".storage-layouts",
  },
  storageLayoutConfig: {
    contracts: ['src/Hoku.sol:Hoku'],
    fullPath: true
  },
  resolve: {
    alias: {
      "@openzeppelin/contracts": path.resolve(__dirname, "lib/openzeppelin-contracts/contracts"), 
    },
  },
};
