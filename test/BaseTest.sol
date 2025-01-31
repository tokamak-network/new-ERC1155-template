// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { AssetFactory } from "../contracts/AssetFactory.sol";
import { AssetFactoryProxy } from "../contracts/AssetFactoryProxy.sol";
import { Treasury } from "../contracts/Treasury.sol";
import { TreasuryProxy } from "../contracts/TreasuryProxy.sol";
import { L2StandardERC20 } from "./mockContracts/L2StandardERC20.sol";
import { AssetFactoryStorage } from "../contracts/AssetFactory.sol";
import { TreasuryStorage } from "../contracts/TreasuryStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseTest is Test {

    using SafeERC20 for IERC20;


    address payable owner;
    address payable user1;
    address payable user2;
    address payable user3;

    AssetFactory assetfactory;
    AssetFactoryProxy assetfactoryProxy;
    address assetfactoryProxyAddress;
    Treasury treasury;
    TreasuryProxy treasuryProxy;
    address payable treasuryProxyAddress;

    address wston;
    address l1wston;    
    address l2bridge;

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));
        user3 = payable(makeAddr("User3"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wston = address(new L2StandardERC20(l2bridge, l1wston, "Wrapped Ston", "WSTON")); // 27 decimals

        vm.stopPrank();

        // mint some tokens to User1, user2 and user3
        vm.startPrank(l2bridge);
        L2StandardERC20(wston).mint(owner, 1000000 * 10 ** 27);
        L2StandardERC20(wston).mint(user1, 100000 * 10 ** 27);
        L2StandardERC20(wston).mint(user2, 100000 * 10 ** 27);
        L2StandardERC20(wston).mint(user3, 100000 * 10 ** 27);
        vm.stopPrank();

        vm.startPrank(owner);
        // give ETH to User1 and User2 to cover gasFees associated with using VRF functions as well as interacting with thanos
        vm.deal(user1, 1000000 ether);
        vm.deal(user2, 1000000 ether);


// --------------------------- ASSET FACTORY DEPLOYMENT -------------------------------------------------

        // deploy GemFactory
        assetfactory = new AssetFactory();
        assetfactoryProxy = new AssetFactoryProxy();
        assetfactoryProxy.upgradeTo(address(assetfactory));
        assetfactoryProxyAddress = address(assetfactoryProxy);


// ------------------------------- TREASURY DEPLOYMENT -------------------------------------------------

        // deploy and initialize treasury
        treasury = new Treasury();
        treasuryProxy = new TreasuryProxy();
        treasuryProxy.upgradeTo(address(treasury));
        treasuryProxyAddress = payable(address(treasuryProxy));
        Treasury(treasuryProxyAddress).initialize(
            wston,
            assetfactoryProxyAddress
        );

        vm.stopPrank();

        // mint some TON & WSTON to treasury
        vm.startPrank(l2bridge);
        L2StandardERC20(wston).mint(treasuryProxyAddress, 100000 * 10 ** 27);
        vm.stopPrank();


        vm.startPrank(owner);
        uint256[] memory wstonValues = new uint256[](2);
        wstonValues[0] = 10 * 1e27;
        wstonValues[1] = 20 * 1e27;

        string[] memory uris = new string[](2);
        uris[0] = "";
        uris[1] = "";
        
        // initialize gemfactory with newly created contract addreses
        AssetFactory(assetfactoryProxyAddress).initialize(
            owner,
            wston,
            treasuryProxyAddress,
            wstonValues,
            uris
        );

        vm.stopPrank();
    }


    function testSetup() public view {
        address wstonAddress = AssetFactory(assetfactoryProxyAddress).getWstonAddress();
        assert(wstonAddress == address(wston));

        address treasuryAddress = AssetFactory(assetfactoryProxyAddress).getTreasuryAddress();
        assert(treasuryAddress == treasuryProxyAddress);
    }
}
