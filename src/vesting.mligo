#import "@ligo/fa/lib/main.mligo" "FA2"
#import "./errors.mligo" "Errors"

module FA2Module = FA2.SingleAssetExtendable

type vesting_details = {   
  start_time : timestamp;
  end_time : timestamp;
  total_tokens : int;
  claimed_tokens : nat;
}


type extension = {
  admin : address;
  token_id : nat; 
  beneficiaries : (address, vesting_details) big_map; 
  beneficiary_list : address list; 
  freeze_duration : int;
  free_duration_timestamp : timestamp;
  vesting_started : bool; 
  start_time : timestamp; 
}

type storage = extension FA2Module.storage

type ret = operation list * storage
let no_op : operation list = [] 

[@entry]
let start_vesting (start_params : int) (storage : storage) : ret =
  let (freeze_duration) = start_params in
  if Tezos.get_sender() <> storage.extension.admin then failwith(Errors.not_admin)
  else if storage.extension.vesting_started then failwith(Errors.vesting_already_started)
  else 
    let day : int = 86400 * freeze_duration in
    let now : timestamp = Tezos.get_now() in
    let schedule : timestamp = now + day in
    let update_storage = { storage.extension with vesting_started = true; free_duration_timestamp = schedule; start_time = now } in
    no_op, { storage with extension = update_storage }

[@entry]
let claim_tokens () (storage : storage) : ret =
  let beneficiary_address = Tezos.get_sender() in
  match Big_map.find_opt beneficiary_address storage.extension.beneficiaries with
  | None -> failwith("You are not a beneficiary")
  | Some(details) ->
    let now = Tezos.get_now() in
    if now < storage.extension.free_duration_timestamp then
      failwith("You can't claim tokens before the freeze duration ends")
    else
      let total_vesting_time : int = details.end_time - details.start_time in
      let elapsed_time : int = now - details.start_time in
      let claimable_tokens = 
        if now >= details.end_time then details.total_tokens
        else (details.total_tokens * elapsed_time) / total_vesting_time in
      let to_claim = claimable_tokens - details.claimed_tokens in
      if to_claim > 0 then
        let transfer_param = [{ from_ = storage.extension.admin; txs = [{ to_ = beneficiary_address; token_id = storage.extension.token_id; amount = abs to_claim}]}] in
        let (transfer_operations, updated_storage) = FA2Module.transfer transfer_param storage in
        let updated_details = { details with claimed_tokens = abs claimable_tokens } in
        let updated_beneficiaries = Big_map.update beneficiary_address (Some updated_details) storage.extension.beneficiaries in
        (transfer_operations, { updated_storage with extension = { storage.extension with beneficiaries = updated_beneficiaries } })
      else (no_op, storage)

[@entry]
let update_beneficiary (update_params : (address * int * int)) (storage : storage) : ret =
  let (beneficiary, total_tokens, duration) = update_params in
  if Tezos.get_sender() <> storage.extension.admin then
    failwith(Errors.not_admin)
  else if storage.extension.vesting_started then
    failwith("Vesting has already started, cannot update beneficiary")
  else
    let now = Tezos.get_now() in
    let end_time = now + (86400 * duration) in
    let new_details = { start_time = now; end_time = end_time; total_tokens = total_tokens; claimed_tokens = abs 0 } in
    let updated_beneficiaries = Big_map.update beneficiary (Some new_details) storage.extension.beneficiaries in
    no_op, { storage with extension = { storage.extension with beneficiaries = updated_beneficiaries } }


let calculate_claimable_tokens (details : vesting_details) (now : timestamp) (storage : storage) : nat =
  if now >= details.end_time then
    abs details.total_tokens  
  else if now >= storage.extension.free_duration_timestamp then
    let elapsed_time = now - details.start_time in
    let total_vesting_time = details.end_time - details.start_time in
    let tokens = (details.total_tokens * elapsed_time) / total_vesting_time in
    abs tokens
  else
    0n

[@entry]
let kill()(storage : storage) : ret =
  let beneficiary_address = Tezos.get_sender() in
  match Big_map.find_opt beneficiary_address storage.extension.beneficiaries with
    | None -> failwith("You are not a beneficiary")
    | Some(details) ->
      let now = Tezos.get_now() in
      let claimable_tokens =
        if now >= details.end_time then
          details.total_tokens  
        else if now >= storage.extension.free_duration_timestamp then
          let elapsed_time = now - details.start_time in
          let total_vesting_time = details.end_time - details.start_time in
          (details.total_tokens * elapsed_time) / total_vesting_time 
        else 0 in
      let to_claim = claimable_tokens - details.claimed_tokens in
      if to_claim > 0 then
        let  _transfer_operations = [{ from_ = storage.extension.admin; txs = [{ to_ = beneficiary_address; token_id = storage.extension.token_id; amount = abs to_claim}]}] in
        let updated_details = { details with claimed_tokens = abs claimable_tokens } in
        let _updated_beneficiaries = Big_map.update beneficiary_address (Some updated_details) storage.extension.beneficiaries in
        (no_op, storage)
      else
        (no_op, storage)

