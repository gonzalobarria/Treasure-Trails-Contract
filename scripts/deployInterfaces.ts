import { ethers } from 'hardhat';

async function main() {
  const Utils = await ethers.getContractFactory('Utils');
  const utils = await Utils.deploy();

  await utils.deployed();

  console.log(`Utils deployed to ${utils.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
