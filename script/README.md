

    
cast code 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE --rpc-url http://localhost:8545

## Define project constants
```shell
export DEPLOYER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export MUSD_ADDRESS=0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE
export USDC_ADDRESS=0xbA9986D2381edf1DA03B0B9c1f8b00dc4AacC369
export USDC_WHALE=0x45f1A95A4D3f3836523F5c83673c797f4d4d263B
export RPC_URL=http://localhost:8545
```

## Add USDC to deployer account
Use known USDC whale address to fund the deployer account with USDC.

```shell
cast send $USDC_ADDRESS \
    "transfer(address,uint256)" $DEPLOYER_ADDRESS 10000000000 \
    --from $USDC_WHALE \
    --unlocked \
    --rpc-url $RPC_URL
```

### Check USDC balance of deployer account
```shell
cast call $USDC_ADDRESS \
    "balanceOf(address)(uint256)" $DEPLOYER_ADDRESS \
    --rpc-url $RPC_URL
```


## Run script to deploy test token MUSD and create pool MUSD/USDC
```shell
forge script script/CreateLocalhostPool.sol:CreateLocalhostPoolScript --rpc-url $RPC_URL --broadcast --unlocked
```

## Check existence of the MUSD token contract after deployment
```shell
cast code $MUSD_ADDRESS --rpc-url $RPC_URL
```
The expected result should be non zero, indicating that the contract is deployed.