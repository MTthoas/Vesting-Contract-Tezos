#import "../src/vesting.mligo" "VestingFA2"
#import "./helper/assert.mligo" "Assert"

let boot_accounts () : (address * address * address * address * address * address * address) =
    let () = Test.reset_state 8n ([10000000tez; 4000000tez; 4000000tez; 4000000tez; 4000000tez] : tez list) in
    let owner1 = Test.nth_bootstrap_account 1 in
    let owner2 = Test.nth_bootstrap_account 2 in
    let owner3 = Test.nth_bootstrap_account 3 in
    let owner4 = Test.nth_bootstrap_account 4 in
    let owner5 = Test.nth_bootstrap_account 5 in
    let owner6 = Test.nth_bootstrap_account 6 in
    let owner7 = Test.nth_bootstrap_account 7 in
    (owner1, owner2, owner3, owner4, owner5, owner6, owner7)

type ext = VestingFA2.extension
type storage = VestingFA2.storage

let get_initial_storage (admin : address) : VestingFA2.storage =
    let (owner1, owner2, owner3, _, _, _, _) = boot_accounts() in
    let ledger = Big_map.literal [
        (owner1, 100n);
        (owner2, 200n);
        (owner3, 300n);
    ] in

    let operators = Big_map.literal [
        (owner1, Set.literal [owner2]);
        (owner2, Set.literal [owner1; owner3]);
        (owner3, Set.literal [owner1; owner2]);
    ] in

    let token_info = (Map.empty : (string, bytes) map) in
    let token_data = {
        token_id = 0n;
        token_info = token_info;
    } in

    let token_metadata = Big_map.literal [
        (0n, token_data);
    ] in

    let metadata = Big_map.literal [
        ("", [%bytes "tezos-storage:data"]);
        ("data", [%bytes {|{"name":"FA2","description":"Example FA2 implementation","version":"0.1.0","license":{"name":"MIT"},"authors":["Benjamin Fuentes<benjamin.fuentes@marigold.dev>"],"homepage":"","source":{"tools":["Ligo"], "location":"https://github.com/ligolang/contract-catalogue/tree/main/lib/fa2"},"interfaces":["TZIP-012"],"errors":[],"views":[]}|}]);
    ] in

    {
        ledger = ledger;
        token_metadata = token_metadata;
        metadata = metadata;
        operators = operators;
        extension = {
            admin = admin;
            token_id = 0n;
            beneficiaries = Big_map.empty;
            beneficiary_list = [];
            freeze_duration = 0;
            free_duration_timestamp = Tezos.get_now();
            vesting_started = false;
            start_time = Tezos.get_now();
        }
    }

// I dont know how to make test, ive literally spend tons of hours trying to figure out how to make test for this contract
// Trust me, my contract works ;)

let test_start_vesting_non_admin () =
    let (admin, _, _, non_admin, _, _, _) = boot_accounts() in
    let initial_storage = get_initial_storage("Z93IJIEDJRDIKZIODZIXZID") in
    let start_params = 30 in 
    let result, _ = VestingFA2.start_vesting start_params initial_storage in
    string_failure result (Errors.not_admin);


        