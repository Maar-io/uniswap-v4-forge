# Uniswap V4 Swaps - Localhost Setup

## Start a local Ethereum node by using Soneium mainnet fork
```shell
anvil --fork-url https://rpc.soneium.org \
      --fork-block-number 10000000 \
      --fork-chain-id 1868 \
      --chain-id 31337 \
      --port 8545 \
      --host 0.0.0.0 \
      --auto-impersonate
```

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
    "transfer(address,uint256)" $DEPLOYER_ADDRESS 100000000000 \
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


## Run script to deploy test token MUSD and create pools
* MUSD/USDC
* MUSD/ETH

```shell
forge script script/CreateLocalhostPool.sol:CreateLocalhostPoolScript --rpc-url $RPC_URL --broadcast --unlocked
```

## Check existence of the MUSD token contract after deployment
```shell
cast code $MUSD_ADDRESS --rpc-url $RPC_URL
```
The expected result should be non zero, indicating that the contract is deployed.

## Start your frontend application
```shell
pnpm run dev
```

## Set up you Metamask wallet
1. Open Metamask and switch to the "Localhost" network. If you don't have it, add a new network with the following parameters:
   - Network Name: Localhost
   - New RPC URL: http://localhost:8545
   - Chain ID: 31337
   - Currency Symbol: ETH
2. Import the deployer account using the private key:
   - Use well known private key for the anvil/hardhat test account 0.
     - Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
     - Account address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
     - This account has enough ETH, USDC and MUSD if you followed previous steps.
  
## Verify MUSD token contract address
Make sure that the MUSD token contract address is set in your frontend application. 
After running forge script, the MUSD token address should be `0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE`. If it is not, copy the address from the script output and set MUSDC address in your frontend application in `lib/uniswap/constants.ts` file.
