// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TreasuryStorage {
    address internal assetFactory;
    address internal wston;
    
    bool paused = false;
    bool internal initialized;

    error InvalidAddress();
    error UnsuffiscientWstonBalance();
    error NotEnoughWstonAvailableInTreasury();
}