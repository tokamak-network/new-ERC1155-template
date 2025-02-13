# Deploy your protocol on THANOS (TRH)


## Bridge WSTON to Optimism

use the `bridgeWstonToThanos.js` script to transfer your WSTON to arbitrum
Please ensure your .env file is up to date.
run:

```
npx hardhat run scripts/optimism/bridgeWstonToThanos.js --network l1
```
NB: please first adjust the amount to bridge within the script (line 12)

## deploy your STON token on Optimism
