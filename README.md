# Overview

This repository is designed to facilitate the creation of new ERC1155 tokens that are backed by WSTON tokens. It is intended for deployment on the Ethereum network or any Layer 2 blockchain that supports smart contract deployment.

## installation

you must have foundry and hardhat installed prior installing the dependancies and/or compile

```
curl -L https://foundry.paradigm.xyz | bash
```
```
npm install --save-dev hardhat
```

you know you've done it right if you see `0.2.0` when you `forge --version` and `2.22.17` when you `npx hardhat --version`

install the project dependancies 
```
forge install
```
and
```
sudo yarn install
``` 

compile the contracts
```
forge compile
```
or
```
npx hardhat compile
```


## Prerequisite

In order to make this project work efficiently, project owners must ensure that WSTON token is deployed onto the targeted chain. 
