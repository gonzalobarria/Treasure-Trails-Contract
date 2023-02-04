import { ethers } from 'hardhat';

async function main() {
  const TreasureTrailsXP = await ethers.getContractFactory('TreasureTrailsXP', {
    libraries: {
      Utils: process.env.UTILS_ADDRESS || '',
    },
  });
  const treasureTrailsXP = await TreasureTrailsXP.deploy(
    'TreasureTrailsPark',
    3
  );

  await treasureTrailsXP.deployed();

  console.log(`TreasureTrailsXP deployed to ${treasureTrailsXP.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
