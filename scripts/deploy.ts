// Declare a contract.
// launch with npx ts-node src/scripts/9.declareContract.ts
// Coded with Starknet.js v5.16.0, Starknet-devnet-rs v0.1.0

import { Account, json, RpcProvider, Contract } from "starknet";
import fs from "fs";
import * as dotenv from "dotenv";
dotenv.config();


async function main(classHash: string) {
    // const provider = new RpcProvider({ nodeUrl: "http://127.0.0.1:5050/rpc" }); // only for starknet-devnet-rs
    // const provider = new RpcProvider({ nodeUrl: `https://starknet-sepolia.infura.io/v3/${process.env.STARKNET_API_KEY}` }); // only for starknet-devnet-rs
    const provider = new RpcProvider({ nodeUrl: `https://starknet-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_STARKNET_API_KEY}` });

    console.log("Provider connected");

    // initialize existing predeployed account 0 of Devnet
    const privateKey = process.env.PRIVATE_KEY ?? "";
    const accountAddress: string = process.env.ACCOUNT_ADDRESS ?? "";
    const account = new Account(provider, accountAddress, privateKey, '1');
    console.log("Account connected\n");

    // const deployResponse = await account.deployContract({ classHash: classHash });
    const deployResponse = await account.deployContract({ classHash: classHash, constructorCalldata: [100, "0x05f7151ea24624e12dde7e1307f9048073196644aa54d74a9c579a257214b542", accountAddress] });
    await provider.waitForTransaction(deployResponse.transaction_hash);

    // read abi of Test contract
    const { abi: testAbi } = await provider.getClassByHash(classHash);
    if (testAbi === undefined) {
        throw new Error('no abi.');
    }

    // Connect the new contract instance:
    const myTestContract = new Contract(testAbi, deployResponse.contract_address, provider);
    console.log('✅ Test Contract connected at =', myTestContract.address);
}

const classHash_counter_contract = "0x76c80722f35c979bcd5a8646a23dab5ba7dae6414ccad56019732dcf7cb8c9";
main(classHash_counter_contract)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });