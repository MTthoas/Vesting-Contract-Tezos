#import "ligo-extendable-fa2/lib/multi_asset/fa2.mligo" "FA2"
#import "./storage.mligo" "Storage"
#import "./extension.mligo" "Extension"
#import "./errors.mligo" "Errors"
#import "./token_total_supply.mligo" "TokenTotalSupply"

type vesting_schedule = {
  start_time : timestamp;
  end_time : timestamp;
  total_amount : nat;
}

type token_total_supply = TokenTotalSupply.t
type gen_storage = Storage.t
type storage = token_total_supply gen_storage
type result = operation list * storage
type gen_extension = Extension.t
type extension = token_total_supply gen_extension

type contract_storage = {
  admin : address;
  fa2_address : address;
  vesting_schedules : (address, vesting_schedule) map;
  claimed : (address, nat) map;
  vesting_started : bool;
}

type action =
  | StartVesting of timestamp * timestamp * nat
  | Claim

let no_operation : operation list = []

let not_admin = "Not admin"
let vesting_already_started = "Vesting already started"
let not_yet_claimable = "Not yet claimable"
let no_vesting_schedule = "No vesting schedule for this address"
let all_claimed = "All funds already claimed"

[@entry]
let start_vesting (params : address * timestamp * timestamp * nat) (s : contract_storage) : operation list * contract_storage =
  let (beneficiary, start_time, end_time, total_amount) = params in (* Extrait les paramètres de la fonction. *)
  if Tezos.get_sender() <> s.admin then failwith(not_admin) (* Vérifie si l'appelant est l'administrateur. *)
  else if Map.mem beneficiary s.vesting_schedules then failwith(vesting_already_started) (* Vérifie si le bénéficiaire a déjà un calendrier de vesting. *)
  else if start_time >= end_time then failwith("Invalid vesting schedule") (* Vérifie si le calendrier de vesting est valide. *)
  else
    // let schedule = {start_time; end_time; total_amount} in (* Crée un nouveau calendrier de vesting. *)
    // let updated_schedules = Map.add beneficiary schedule s.vesting_schedules in (* Ajoute le calendrier au stockage. *)
    // no_operation, {s with vesting_schedules = updated_schedules} (* Retourne aucune opération et le stockage mis à jour. *)
    (* Logique pour transférer les tokens du FA2 ici *)
    let transfer_params = { from_ = Tezos.get_sender(); txs = [ { to_ = s.fa2_address; token_id = 0n; amount = total_amount } ] } in
    let transfer_op = FA2.transfer transfer_params in


    
    let schedule = {start_time; end_time; total_amount} in (* Crée un nouveau calendrier de vesting. *)
    let updated_schedules = Map.add beneficiary schedule s.vesting_schedules in (* Ajoute le calendrier au stockage. *)
    transfer_op, {s with vesting_schedules = updated_schedules} (* Retourne l'opération de transfert et le stockage mis à jour. *)

[@entry]
let claim (beneficiary : address) (s : contract_storage) : operation list * contract_storage =
  match Map.find_opt beneficiary s.vesting_schedules with 
  | None -> failwith(no_vesting_schedule)
  | Some schedule ->
    let now = Tezos.get_now() in
    if now < schedule.start_time then failwith(not_yet_claimable)
    else
      let claimed_so_far = match Map.find_opt beneficiary s.claimed with | None -> 0n | Some amount -> amount in (* Get the amount already claimed by the beneficiary. *)
      let total_vesting_time = schedule.end_time - schedule.start_time in
      let time_elapsed = now - schedule.start_time in
      let claimable_amount_int = (time_elapsed * schedule.total_amount) / total_vesting_time in
      (** claimed fo far is a nat**)
      let amount_to_claim = claimable_amount_int - claimed_so_far in
      if amount_to_claim = 0 then failwith(all_claimed)
      else
        let transformIntToNat : nat = abs(amount_to_claim) in (** transform int to nat **)
        let updated_claimed = Map.add beneficiary transformIntToNat s.claimed in
        no_operation, { s with claimed = updated_claimed }