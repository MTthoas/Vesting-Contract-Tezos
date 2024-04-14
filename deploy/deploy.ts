import { InMemorySigner } from "@taquito/signer";
import { TezosToolkit } from "@taquito/taquito";
import Contract from '../compiled/vesting.mligo.json'; // Ensure the path is correct
import * as dotenv from 'dotenv';

dotenv.config();

const ADMIN_ADRESS = process.env.ADMIN_ADRESS;
const ADMIN_SECRET_KEY = process.env.ADMIN_PRIVATE_KEY;

const RPC_ENDPOINT = "http://ghostnet.tezos.marigold.dev";

async function main() {
  if (!ADMIN_ADRESS || !ADMIN_SECRET_KEY){
    throw new Error("Please provide ADMIN_ADRESS and ADMIN_SECRET_KEY in .env file");
  }
  const Tezos = new TezosToolkit(RPC_ENDPOINT);

  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(ADMIN_SECRET_KEY),
  });

  const currentTimestamp = Math.floor(Date.now() / 1000); 
  
  const vestingDetails = {
    address: ADMIN_ADRESS,
    start_time: currentTimestamp,
    end_time: currentTimestamp + 86400, 
    total_tokens: 1000, 
    claimed_tokens: 0, 
  };

  const initialStorage = {
    extension: {
      admin: ADMIN_ADRESS,
      token_id: 0,
      beneficiaries: new Map([[ADMIN_ADRESS, vestingDetails]]),
      beneficiary_list: [ADMIN_ADRESS],
      ledger: new Map([]),
      freeze_duration: 1, 
      free_duration_timestamp: currentTimestamp, 
      vesting_started: false,
      start_time: currentTimestamp, 
    },
    ledger: new Map([]),
    metadata: new Map([]),
    operators: new Map([]),
    token_metadata: new Map([])
  };

  try {
      const originated = await Tezos.contract.originate({
          code: Contract,
          storage: initialStorage,
      });

      console.log(`Waiting for contract ${originated.contractAddress} to be confirmed...`);
      await originated.confirmation(2);
      console.log("Confirmed contract:", originated.contractAddress);
  } catch (error) {
      console.error("Error during contract deployment:", error);
  }
}

main();
