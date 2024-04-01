#import "ligo-extendable-fa2/lib/single_asset/fa2.mligo" "FA2"
#import "./errors.mligo" "Errors"

type vesting_details = {
  start_time : timestamp;
  end_time : timestamp;
  total_tokens : nat;
}

type beneficiary = {
  schedule : vesting_details;
  claimed : nat;
}

type fa2_storage = FA2.storage
type extension = unit
type extended_storage = extension fa2_storage

type parameter = [@layout:comb]
    | Transfer of FA2.transfer
    | Balance_of of FA2.balance_of
    | Update_operators of FA2.update_operators

type storage = {
  admin : address;
  fa2_address : address;
  fa2_token_id : nat;
  beneficiaries : (address, beneficiary) map;
  vesting_started : bool;
  vesting_schedules : (address, vesting_details) map;
}

let no_operation : operation list = []
type return = operation list * storage

let send (transfers : FA2.transfer) (target_fa2_address : address) : operation = 
    [@no_mutation] let fa2_contract_opt : FA2.transfer contract option = Tezos.get_entrypoint_opt "%transfer" target_fa2_address in
    match fa2_contract_opt with
    | Some contr -> Tezos.transaction (transfers) 0mutez contr
    | None -> (failwith Errors.unknown_contract_entrypoint : operation)
 
let calculate_tokens_to_claim (now : timestamp) (schedule : vesting_details) : nat =
    let total_time = schedule.end_time - schedule.start_time in
    let elapsed_time = now - schedule.start_time in
    let tokens_to_claim = (elapsed_time * schedule.total_tokens) / total_time in
    if abs tokens_to_claim > schedule.total_tokens 
    then schedule.total_tokens else abs tokens_to_claim
    

// Start: Débute la période de vesting et le transfert initial des tokens
[@entry]
let start (params : address * timestamp * timestamp * nat) (s : storage) : return =
  let (beneficiary, start_time, end_time, total_tokens) = params in
  if Tezos.get_sender() <> s.admin then failwith("Only the admin can start the vesting period")
  else if s.vesting_started then failwith("Vesting period has already started")
  else if start_time >= end_time then failwith("Invalid vesting schedule") (* Vérifie si le calendrier de vesting est valide. *)
  else
      let schedule = {start_time; end_time; total_tokens} in (* Crée un nouveau calendrier de vesting. *)
      let new_beneficiary = {schedule; claimed = 0n} in (* Crée un nouveau bénéficiaire. *) 
      let new_beneficiaries = Map.add beneficiary new_beneficiary s.beneficiaries in (* Ajoute le bénéficiaire à la liste des bénéficiaires. *)
      let new_storage = {s with vesting_started = true; beneficiaries = new_beneficiaries} in (* Met à jour le stockage. *)
      no_operation, new_storage

[@entry]
let claim () (s : storage) : return =
  let beneficiary = Tezos.get_sender() in
  match Map.find_opt beneficiary s.beneficiaries with
  | None -> failwith("Beneficiary not found")
  | Some(b) ->
      let now = Tezos.get_now() in
      if now < b.schedule.start_time then failwith("Vesting period has not started yet")
      else no_operation, s
        let tokens_to_claim = calculate_tokens_to_claim now b.schedule in
        let sender_ = Tezos.get_sender() in
        if tokens_to_claim > 0n then
          let transfer_list : FA2.transfer = [{from_ = s.fa2_address; txs = [{to_ = sender_; token_id = s.fa2_token_id; amount = tokens_to_claim }]}] in
          let op = send (Transfer transfer_list) s.fa2_address in
          let new_beneficiary = {b with claimed = b.claimed + tokens_to_claim} in
          let new_beneficiaries = Map.add beneficiary new_beneficiary s.beneficiaries in
          let new_storage = {s with beneficiaries = new_beneficiaries} in
          op, new_storage
        else no_operation, s




// // UpdateBeneficiary: Ajoute ou met à jour un bénéficiaire avant le début du vesting
// [@entry]
// let update_beneficiary (param : address * vesting_details) (s : storage) : operation list * storage =
//   if Tezos.get_sender <> s.admin then failwith("Only the admin can update beneficiaries")
//   else if s.vesting_started then failwith("Cannot update beneficiaries after vesting has started")
//   else 
//     let (beneficiary, details) = param in
//     let updated_vesting = Map.add beneficiary details s.vesting in
//     ([], { s with vesting = updated_vesting })

// // Claim: Permet aux bénéficiaires de réclamer leurs tokens disponibles
// [@entry]
// let claim (param : unit) (s : storage) : operation list * storage =
//   let beneficiary = Tezos.sender in
//   match Map.find_opt beneficiary s.vesting with
//   | None -> failwith("Beneficiary not found")
//   | Some(details) ->
//       let now = Tezos.now in
//       if now < details.start_time then failwith("Vesting period has not started yet")
//       else
//         let tokens_to_claim = calculate_tokens_to_claim now details in // À implémenter
//         if tokens_to_claim > 0n then
//             let ops = transfer_fa2_tokens s.fa2_contract beneficiary s.fa2_token_id tokens_to_claim in // À implémenter
//             let updated_details = { details with tokens_claimed = details.tokens_claimed + tokens_to_claim } in
//             let updated_vesting = Map.add beneficiary updated_details s.vesting in
//             (ops, { s with vesting = updated_vesting })
//         else ([], s)

// // Fonction helper pour calculer le nombre de tokens à réclamer
// let calculate_tokens_to_claim (now : timestamp) (details : vesting_details) : nat =
//   (* Calculer la logique de proportion des tokens basée sur le temps écoulé *)
//   (* Cette partie dépend de la logique spécifique de votre vesting *)

// // Fonction helper pour transférer les tokens FA2
// let transfer_fa2_tokens (fa2_contract : address) (beneficiary : address) (token_id : nat) (amount : nat) : operation list =
//     (* Construire l'opération de transfert FA2 ici *)
//     (* Cette partie nécessite d'envoyer une opération au contrat FA2 *)
    
