import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-noir";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: { enabled: true, runs: 1 },
      viaIR: false,  // Disable viaIR to avoid stack depth issues
    },
  },
  noir: {
    version: "1.0.0-beta.3",  // Must match our circuits
  },
  paths: {
    noir: "noir",  // Will symlink circuits here
    sources: "contracts",
  },
};

export default config;
