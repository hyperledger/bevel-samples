require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.6.1",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10,
      },
    },
  },
  allowUnlimitedContractSize: true,
};
