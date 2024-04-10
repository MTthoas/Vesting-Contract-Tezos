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
  fa2_contract : address; // L'adresse du contrat FA2
  token_id : nat; // L'identifiant du token FA2
  beneficiaries : (address, vesting_details) map; // Les bénéficiaires et leurs détails de vesting
  // Free_duration can be 1 or 2, or 3, in integer form
  freeze_duration : int;
  free_duration_timestamp: timestamp;
  vesting_started : bool; // Si la période de vesting a commencé
  start_time : timestamp; // L'heure de début de la période de vesting
}

type storage = extension FA2Module.storage
type ret = operation list * storage
let no_op : operation list = [] (* Liste d'opérations vide pour les cas où aucune opération blockchain n'est nécessaire. *)

[@entry]
let transfer (param: FA2Module.TZIP12.transfer)(storage: storage) : ret =
  FA2Module.transfer param storage

[@entry]
let start_vesting (start_params : int) (storage : storage) : operation list * storage =
  let (freeze_duration) = start_params in
  if Tezos.get_sender() <> storage.extension.admin then failwith(Errors.not_admin)
  else if storage.extension.vesting_started then failwith(Errors.vesting_already_started)
  else 
    let day : int = 86400 * freeze_duration in
    let now : timestamp = Tezos.get_now () in
    let shedule : timestamp = now + day in
    let update_storage = { storage.extension with vesting_started = true; free_duration_timestamp = shedule; start_time = Tezos.get_now() } in
    no_op, { storage with extension = update_storage }

[@entry]
let claim_tokens () (storage : storage) : ret =
  let beneficiary_address = Tezos.get_sender() in
  match Map.find_opt beneficiary_address storage.extension.beneficiaries with
  | None -> failwith("You are not a beneficiary")
  | Some(details) ->
    let now = Tezos.get_now () in
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
        let updated_beneficiaries = Map.add beneficiary_address updated_details storage.extension.beneficiaries in
        (transfer_operations, { updated_storage with extension = { storage.extension with beneficiaries = updated_beneficiaries } })
      else (no_op, storage)
      



  

// let update_beneficiary (beneficiary_details : address * nat * timestamp * timestamp) (storage : storage) : storage =
//   let (beneficiary_address, total_tokens, start_time, end_time) = beneficiary_details in
//   if Tezos.get_sender() <> storage.admin then failwith(Errors.not_admin)
//   else if storage.vesting_started then failwith(Errors.vesting_already_started)
//   else
//     let new_details = {start_time = start_time; end_time = end_time; total_tokens = total_tokens; claimed_tokens = 0n} in
//     let new_beneficiaries = Map.add beneficiary_address new_details storage.beneficiaries in
//     { storage with beneficiaries = new_beneficiaries }

// let claim_tokens (request : unit) (storage : storage) : operation list * storage =
  // let beneficiary_address = Tezos.get_sender() in
  // match Map.find_opt beneficiary_address storage.beneficiaries with
  // | None -> failwith("You are not a beneficiary")
  // | Some(details) ->
  //   let now = Tezos.get_now () in

  //   if now < details.start_time + int storage.freeze_duration then
  //     failwith("You can't claim tokens before the freeze duration ends")
    
  //   // let details_start_time : timestamp = details.start_time in
  //   // let storage_freeze_duration : int = int storage.freeze_duration in
  //   // let elapsed_time : int = now - (details_start_time + storage_freeze_duration) in

  //   // let not_date : bool = Tezos.get_now () < details.start_time + storage_freeze_duration in
  //   // if not_date then failwith("You can't claim tokens before the freeze duration")
  //   else
  //     let total_vesting_time : int = details.end_time - details.start_time in
  //     let elapsed_time : int = now - details.start_time in

  //     ([], storage)
      // let claimable_tokens =
      //   if now >= details.end_time then details.total_tokens
      //   else (detailsToken * elapsedTime) / total_vesting_time in

      // let to_claim = claimable_tokens - details.claimed_tokens in
      // if to_claim > 0n then
      //   let transfer_operation =
      //     FA2.transfer
      //       [{ from_ = storage.admin; txs = [{ to_ = beneficiary_address; token_id = storage.token_id; amount = to_claim }] }]
      //       storage.fa2_contract in
      //   let updated_details = { details with claimed_tokens = claimable_tokens } in
      //   let updated_beneficiaries = Map.add beneficiary_address updated_details storage.beneficiaries in
      //   ([transfer_operation], { storage with beneficiaries = updated_beneficiaries })
      // else ([], storage)
