#import "ligo-extendable-fa2/lib/multi_asset/fa2.mligo" "FA2"

type token_metadata = {
  token_id : nat; (* Définit le type pour les métadonnées de token, incluant l'ID du token et sa quantité. *)
  amount : nat;
}

type vesting_schedule = {
  start_time : timestamp; (* Définit une structure pour le calendrier de vesting, incluant le début, la fin, et la quantité totale. *)
  end_time : timestamp;
  total_amount : nat;
}

type storage = {
  admin : address; (* Le stockage principal du contrat, contenant l'admin, l'adresse FA2, les calendriers de vesting et les montants réclamés. *)
  fa2_address : address;
  vesting_schedules : (address, vesting_schedule) map;
  claimed : (address, nat) map; (* Mappe l'adresse du bénéficiaire à la quantité déjà réclamée. *)
}

type action =
  | StartVesting of address * timestamp * timestamp * nat (* Définit les types d'actions possibles, comme commencer le vesting ou réclamer des tokens. *)
  | Claim of address

let no_op : operation list = [] (* Liste d'opérations vide pour les cas où aucune opération blockchain n'est nécessaire. *)

type get_vesting_schedule_response = {
  beneficiary : address;
  start_time : timestamp;
  end_time : timestamp;
  total_amount : nat;
  amount_claimed : nat;
}

(* Errors *)
let not_admin = "Not admin"
let vesting_already_started = "Vesting already started"
let not_yet_claimable = "Not yet claimable"
let no_vesting_schedule = "No vesting schedule for this address"
let all_claimed = "All funds already claimed"


type request_action =
  | GetVestingSchedule of address

let get_vesting_schedule (beneficiary : address) (s : storage) : vesting_schedule option =
  Map.find_opt beneficiary s.vesting_schedules (* Retourne le calendrier de vesting pour un bénéficiaire donné. *)

[@entry]
let start_vesting (params : address * timestamp * timestamp * nat) (s : storage) : operation list * storage =
  let (beneficiary, start_time, end_time, total_amount) = params in (* Extrait les paramètres de la fonction. *)
  if Tezos.get_sender() <> s.admin then failwith(not_admin) (* Vérifie si l'appelant est l'administrateur. *)
  else if Map.mem beneficiary s.vesting_schedules then failwith(vesting_already_started) (* Vérifie si le bénéficiaire a déjà un calendrier de vesting. *)
  else if start_time >= end_time then failwith("Invalid vesting schedule") (* Vérifie si le calendrier de vesting est valide. *)
  else
    let schedule = {start_time; end_time; total_amount} in (* Crée un nouveau calendrier de vesting. *)
    let updated_schedules = Map.add beneficiary schedule s.vesting_schedules in (* Ajoute le calendrier au stockage. *)
    no_op, {s with vesting_schedules = updated_schedules} (* Retourne aucune opération et le stockage mis à jour. *)

(* Claiming tokens, 
- Nous utilisons Map.find_opt pour obtenir la quantité déjà réclamée par le bénéficiaire. 
Si aucune quantité n'a été réclamée précédemment, nous utilisons 0n comme valeur par défaut. 

- Nous calculons la durée totale du vesting et le temps écoulé depuis le début du vesting.
Si le temps écoulé est inférieur à la durée totale, nous retournons une erreur.
Ensuite, nous déterminons la quantité qui peut être réclamée à ce moment, proportionnellement au temps écoulé.
*)

[@entry]
let claim (beneficiary : address) (s : storage) : operation list * storage =
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
        no_op, { s with claimed = updated_claimed }

    
