// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./BaseTest.sol";

contract AssetFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    // --------------------------- INITIALIZE FUNCTION ----------------------------

    /**
     * @notice tests the behavior of initialize function if called twice
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        uint256[] memory wstonValues = new uint256[](2);
        wstonValues[0] = 10 * 1e27;
        wstonValues[1] = 20 * 1e27;

        string[] memory uris = new string[](2);
        uris[0] = "";
        uris[1] = "";
        vm.startPrank(owner);
        vm.expectRevert();
        AssetFactory(assetfactoryProxyAddress).initialize(
            owner,
            wston,
            treasuryProxyAddress,
            wstonValues,
            uris
        );
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of setTreasury function
     */
    function testSetTreasury() public {
        vm.startPrank(owner);
        AssetFactory(assetfactoryProxyAddress).setTreasury(user1);
        vm.stopPrank();
        assert(AssetFactory(assetfactoryProxyAddress).getTreasuryAddress() == user1);
    }

    /**
     * @notice tests the behavior of setWston function
     */
    function testSetWston() public {
        vm.startPrank(owner);
        AssetFactory(assetfactoryProxyAddress).setWston(user1);
        vm.stopPrank();
        assert(AssetFactory(assetfactoryProxyAddress).getWstonAddress() == user1);
    }

    /**
     * @notice tests the behavior of SetWstonValuesAssociatedWtihTokenIds function
     */
    function testSetWstonValuesAssociatedWtihTokenIds() public {
        uint256[] memory wstonValues = new uint256[](2);
        wstonValues[0] = 10 * 1e27;
        wstonValues[1] = 20 * 1e27;
        vm.startPrank(owner);
        AssetFactory(assetfactoryProxyAddress).setWstonValuesAssociatedWtihTokenIds(wstonValues);
        vm.stopPrank();
        assert(AssetFactory(assetfactoryProxyAddress).getWstonValuePerNft(0) == wstonValues[0]);
    }

    /**
     * @notice tests the behavior of SetWstonValuesAssociatedWtihTokenIds function if the number of values is wrong
     */
    function testSetWstonValuesAssociatedWtihTokenIdsShouldRevertIfWrongNumberOfValues() public {
        uint256[] memory wstonValues = new uint256[](1);
        wstonValues[0] = 10 * 1e27;
        vm.startPrank(owner);
        vm.expectRevert(AssetFactoryStorage.WrongNumberOfValues.selector);
        AssetFactory(assetfactoryProxyAddress).setWstonValuesAssociatedWtihTokenIds(wstonValues);
        vm.stopPrank();
    }

    // --------------------------- MINT ASSET FUNCTION ----------------------------

    /**
     * @notice tests the behavior of mintAsset function
     */
    function testMintAsset() public {
        vm.startPrank(treasuryProxyAddress);
        vm.expectEmit(true, true, true, true);
        emit AssetFactoryStorage.NFTMinted(1,user1,1);
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,user1,1);
        uint256 balance = AssetFactory(assetfactoryProxyAddress).balanceOf(user1,1);
        assert(balance == 1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintAsset function if the caller is not the treasury
     */
    function testMintAssetShouldRevertIfNotTreasury() public {
        vm.startPrank(user1);
        vm.expectRevert();
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,user1,1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintAsset function if the contract is paused
     */
    function testMintAssetShouldRevertIfContractPaused() public {
        vm.startPrank(owner);
        AssetFactory(assetfactoryProxyAddress).pause();
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        vm.expectRevert(AssetFactoryStorage.ContractPaused.selector);
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,user1,1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintAsset function if the tokenId is wrong
     */
    function testMintAssetShouldRevertIfWrongTokenId() public {
        vm.startPrank(treasuryProxyAddress);
        // we pass tokenId = 5 (does not exist)
        vm.expectRevert(AssetFactoryStorage.WrongTokenId.selector);
        AssetFactory(assetfactoryProxyAddress).mintAsset(2,user1,1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintAsset function if the recipient is address 0
     */
    function testMintAssetShouldRevertIfAddressZero() public {
        vm.startPrank(treasuryProxyAddress);
        // we pass _to = address(0) 
        vm.expectRevert(AssetFactoryStorage.AddressZero.selector);
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,address(0),1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintAsset function if the number of tokens to mint is equal to 0
     */
    function testMintAssetShouldRevertIfWrongNumberOfNFT() public {
        vm.startPrank(treasuryProxyAddress);
        // we pass _numberOfNFTToMint = 0
        vm.expectRevert(AssetFactoryStorage.WrongNumberOfNFTToMint.selector);
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,user1,0);
        vm.stopPrank();
    }

    // --------------------------- BURN ASSET FUNCTION ----------------------------

    /**
     * @notice tests the behavior of burnAsset function
     */
     function testBurnAsset() public {
        // we mint an asset for user 1
        testMintAsset();

        uint256 wstonBalanceBefore = IERC20(wston).balanceOf(user1);
        uint256 totalWstonValueBefore = AssetFactory(assetfactoryProxyAddress).getTotalWstonValue(1);

        // burn the asset
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit AssetFactoryStorage.NFTBurnt(1,user1,1);
        AssetFactory(assetfactoryProxyAddress).burnAsset(1,1);
        vm.stopPrank();

        uint256 wstonBalanceAfter = IERC20(wston).balanceOf(user1);
        uint256 totalWstonValueAfter = AssetFactory(assetfactoryProxyAddress).getTotalWstonValue(1);
        assert(wstonBalanceAfter == wstonBalanceBefore + 20 * 1e27);
        assert(totalWstonValueAfter == totalWstonValueBefore - 20 * 1e27);

     }

     /**
     * @notice tests the behavior of burnAsset function should revert if address 0 
     */
    function testBurnAssetShouldRevertIfAddressZero() public {
        // we mint an asset for user 1
        testMintAsset();
        vm.startPrank(address(0));
        vm.expectRevert(AssetFactoryStorage.AddressZero.selector);
        AssetFactory(assetfactoryProxyAddress).burnAsset(1,1);
        vm.stopPrank();

    }

    // --------------------------- CREATE ASSET FUNCTION ----------------------------

    /**
     * @notice tests the behavior of createAsset function
     */
    function testCreateAsset() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit AssetFactoryStorage.Created(2,30 * 1e27,"");
        AssetFactory(assetfactoryProxyAddress).createAsset(30 * 1e27, "");
        vm.stopPrank();

        assert(AssetFactory(assetfactoryProxyAddress).numberOfTokens() == 2);
    }

    /**
     * @notice tests the behavior of createAsset function if the caller is not the owner
     */
    function testCreateAssetShouldRevertIfNotOwner() public { 
        vm.startPrank(user1);
        vm.expectRevert();
        AssetFactory(assetfactoryProxyAddress).createAsset(10 * 1e27, "");
        vm.stopPrank();
    }

        /**
     * @notice tests the behavior of createAsset function if the contract is paused
     */
    function testCreateAssetShouldRevertIfPaused() public {
        vm.startPrank(owner);
        AssetFactory(assetfactoryProxyAddress).pause();
        vm.expectRevert(AssetFactoryStorage.ContractPaused.selector);
        AssetFactory(assetfactoryProxyAddress).createAsset(10 * 1e27, "");
        vm.stopPrank();
    }

    // --------------------------- VIEW FUNCTIONS ----------------------------

    /**
     * @notice tests the behavior of getAsset function
     */
    function testGetAsset() public {
        AssetFactoryStorage.Asset memory asset;
        asset = AssetFactory(assetfactoryProxyAddress).getAsset(0);
        vm.startPrank(user1);
        assert(asset.tokenId == 0);
        assert(asset.wstonValuePerNFT == 10*1e27);
        assert(asset.totalWstonValue == 0);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of getTotalWstonValue function
     */
     function testGetTotalWstonValue() public view {
        uint256 totalWstonValue = AssetFactory(assetfactoryProxyAddress).getTotalWstonValue(0);
        assert(totalWstonValue == 0);
     }

    /**
     * @notice tests the behavior of getWstonValuePerNft function
     */
     function testGetWstonValuePerNft() public view {
        uint256 wstonValuePerNFT = AssetFactory(assetfactoryProxyAddress).getWstonValuePerNft(0);
        assert(wstonValuePerNFT == 10*1e27);
     }

    /**
     * @notice tests the behavior of getAssetsSupplyTotalValue function
     */
     function testGetAssetsSupplyTotalValue() public {
        testMintAsset();
        uint256 totalValue = AssetFactory(assetfactoryProxyAddress).getAssetsSupplyTotalValue();
        assert(totalValue == 20*1e27);
     }

    /**
     * @notice tests the behavior of uri function
     */
     function testUri() public view {
        string memory uri = AssetFactory(assetfactoryProxyAddress).uri(0);
        assert(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked("")));
     }

}