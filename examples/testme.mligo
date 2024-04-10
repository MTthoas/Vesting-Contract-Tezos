(* This is testme.mligo *)

type storage = int
type result = operation list * storage

[@entry]
let increment (delta : int) (store : storage) : result = [], store + delta

[@entry]
let decrement (delta : int) (store : storage) : result = [], store - delta

[@entry]
let reset (_ : unit) (_ : storage) : result = [], 0

// ligo run interpret "increment 32 10" --init-file examples/testme.mligo
// # Outputs:
// # ( LIST_EMPTY() , 42 )