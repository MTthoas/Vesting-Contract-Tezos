(* This is mycontract-test.mligo *)
#import "./helper/bootstrap.mligo" "Bootstrap"
#import "./helper/assert.mligo" "Assert"
#import "../src/counter.mligo" "MyContract"

// type param = MyContract.C parameter_of

let test_initial =
    // Set bootstrap accounts
    let (own1,_own2,_own3,_own4, _,_,_) = Bootstrap.boot_accounts() in

    // Create initial storage and originate contract with it
    let initial_storage = { value = 42; admin = own1 } in

    // Originate contract
    let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
    assert (Test.get_storage addr = initial_storage)

let test_increment =
    let accounts = Bootstrap.boot_accounts () in
    let (own1,_own2,_own3,_own4, _,_,_) = accounts in 

    let initial_storage = { value = 42; admin = own1 } in
    let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in

    let contr = Test.to_contract addr in
    let _r = Test.transfer_to_contract contr (Increment 1) 0tez in

    let current_storage = Test.get_storage addr in
    assert (current_storage.value = 43)

let test_decrement =
    let accounts = Bootstrap.boot_accounts () in
    let (own1,_own2,_own3,_own4, _,_,_) = accounts in 

    let initial_storage = { value = 42; admin = own1 } in
    let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in

    let contr = Test.to_contract addr in
    let _r = Test.transfer_to_contract contr (Decrement 1) 0tez in

    // Decremente by 10
    let _r = Test.transfer_to_contract contr (Decrement 10) 0tez in

    let current_storage = Test.get_storage addr in
    assert (current_storage.value = 31)


let test_reset_failure =
    // create accounts
    let accounts = Bootstrap.boot_accounts () in
    let (own1,own2,_own3,_own4, _,_,_) = accounts in 

    let initial_storage = { 
        value = 42; 
        admin = own1 
    } in
    let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in

    let contr = Test.to_contract addr in
    let () = Test.set_source own2 in
    let r = Test.transfer_to_contract contr (Reset ()) 0tez in
    let () = Assert.string_failure r MyContract.C.Errors.not_admin in

    let current_storage = Test.get_storage addr in
    let () = assert (current_storage.value = 42) in
    ()

let test_reset_success =
    let accounts = Bootstrap.boot_accounts () in
    let (own1,_own2,_own3,_own4, _,_,_) = accounts in 

    let initial_storage = { value = 42; admin = own1 } in
    let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in

    let contr = Test.to_contract addr in
    let () = Test.set_source own1 in
    let r = Test.transfer_to_contract contr (Reset ()) 0tez in
    let () = Assert.tx_success r in

    let current_storage = Test.get_storage addr in
    assert (current_storage.value = 0)