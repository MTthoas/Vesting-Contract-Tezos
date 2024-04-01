let requires_admin  = "NOT_AN_ADMIN"
let token_exist     = "TOKEN_ID_ALREADY_PRESENT"

(* TZIP-17 *)
let dup_permit      = "DUP_PERMIT"
let missigned       = "MISSIGNED"

let max_seconds_exceeded = "MAX_SECONDS_EXCEEDED"
let forbidden_expiry_update = "FORBIDDEN_EXPIRY_UPDATE"

let missing_expiry = "NO_EXPIRY_FOUND"

(* Errors *)
let not_admin = "Not admin"
let vesting_already_started = "Vesting already started"
let not_yet_claimable = "Not yet claimable"
let no_vesting_schedule = "No vesting schedule for this address"
let all_claimed = "All funds already claimed"
let unknown_contract_entrypoint = "Cannot connect to the target transfer token entrypoint"
