"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const signer_1 = require("@taquito/signer");
const taquito_1 = require("@taquito/taquito");
const vesting_mligo_json_1 = __importDefault(require("../compiled/vesting.mligo.json")); // Ensure the path is correct
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const ADMIN_ADRESS = process.env.ADMIN_ADRESS;
const ADMIN_SECRET_KEY = process.env.ADMIN_PRIVATE_KEY;
const RPC_ENDPOINT = "http://ghostnet.tezos.marigold.dev";
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        if (!ADMIN_ADRESS || !ADMIN_SECRET_KEY) {
            throw new Error("Please provide ADMIN_ADRESS and ADMIN_SECRET_KEY in .env file");
        }
        const Tezos = new taquito_1.TezosToolkit(RPC_ENDPOINT);
        Tezos.setProvider({
            signer: yield signer_1.InMemorySigner.fromSecretKey(ADMIN_SECRET_KEY),
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
            const originated = yield Tezos.contract.originate({
                code: vesting_mligo_json_1.default,
                storage: initialStorage,
            });
            console.log(`Waiting for contract ${originated.contractAddress} to be confirmed...`);
            yield originated.confirmation(2);
            console.log("Confirmed contract:", originated.contractAddress);
        }
        catch (error) {
            console.error("Error during contract deployment:", error);
        }
    });
}
main();
