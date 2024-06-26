﻿# Vesting-Contract-Tezos

Create a smart contract (called Vesting) that distributes funds to beneficiaries on a period of time. 
Funds are implemented as a FA2 token (TZIP-12). 

Funds are first frozen during a freeze period (i.e. funds cannot be claimed). Then funds are available (i.e. 
claimable) on time basis. During the vesting period, funds are claimable proportionnaly to the vesting period 
duration. At the end of the vesting period, 100% of funds are claimable. 

The administrator of the Vesting contract is the user who deployed the Vesting contract.

The administrator can call the `Start` entrypoint which will trigger the beginning of the freeze period and the 
lock of funds (i.e. fund transfer from administrator to the Vesting contract) . Once the Vesting contract is 
started, the beneficiaries cannot be changed, and vesting start time and end time cannot be changed.

```bash
make compile
```

```bash
make test
```

```bash
make deploy
```
