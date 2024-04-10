module C = struct
    type storage = { 
        value: int; 
        admin : address 
    }

  type result = operation list * storage

    module Errors = struct
        let not_admin = "Not admin"
    end

  // Two entrypoints
  [@entry] let increment (delta : int) (store : storage) : result = [], { store with value=store.value + delta }
  [@entry] let decrement (delta : int) (store : storage) : result = [], { store with value=store.value - delta }
  [@entry] let reset () (store : storage) : result = 
    let () = assert_with_error (store.admin = (Tezos.get_sender())) Errors.not_admin in 
    [], { store with value=0 }
end
