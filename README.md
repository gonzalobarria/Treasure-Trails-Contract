# Treasure Trails Park Contract

This is the contract with which the Treasure Trails Park App interacts to provide service to its customers.

It is necessary to deploy the Utils library first before deploying the contract:

```shell
npx hardhat node
npx hardhat run scripts/deployLibrary.ts
```

Copy the Library address into the .env file in this project 

It should look like this:

UTILS_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

After this you should run: 

```shell
npx hardhat run scripts/deployTreasureTrailsXP.ts
```

This is the required address to interact with the dApp Treasure Trails Park.

Copy it into the .env-local of the Next.js app of the Treasure Trails Park.

It should look like this:

NEXT_PUBLIC_TREASURE_CONTRACT_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512