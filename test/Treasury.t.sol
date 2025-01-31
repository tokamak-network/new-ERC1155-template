// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./BaseTest.sol";

contract TreasuryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    // --------------------------- INITIALIZE FUNCTION ----------------------------

    /**
     * @notice tests the behavior of initialize function if called twice
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        vm.expectRevert();
        Treasury(treasuryProxyAddress).initialize(
            wston,
            assetfactoryProxyAddress
        );
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of setAssetFactory function
     */
    function testSetAssetFactory() public {
        vm.startPrank(owner);
        Treasury(treasuryProxyAddress).setAssetFactory(user1);
        vm.stopPrank();
        assert(Treasury(treasuryProxyAddress).getAssetFactoryAddress() == user1);
    }

    /**
     * @notice tests the behavior of setWston function
     */
    function testSetWston() public {
        vm.startPrank(owner);
        Treasury(treasuryProxyAddress).setWston(user1);
        vm.stopPrank();
        assert(Treasury(treasuryProxyAddress).getWstonAddress() == user1);
    }

    // --------------------------- TRANSFERWSTON FUNCTION ----------------------------

    /**
     * @notice tests the behavior of transferWSTON function
     */
    function testTransferWston() public {
        vm.startPrank(owner);
        uint256 user1WstonBalanceBefore = IERC20(wston).balanceOf(user1);
        // transfers 10 WSTON to user1
        Treasury(treasuryProxyAddress).transferWSTON(user1, 10*1e27);
        uint256 user1WstonBalanceAfter = IERC20(wston).balanceOf(user1);
        vm.stopPrank();

        assert(user1WstonBalanceAfter == user1WstonBalanceBefore + 10*1e27);
    }

    /**
     * @notice tests the behavior of transferWSTON function should revert if recipient is address 0
     */
    function testTransferWstonShouldRevertIfAddressZero() public {
        vm.startPrank(owner);
        vm.expectRevert(TreasuryStorage.InvalidAddress.selector);
        Treasury(treasuryProxyAddress).transferWSTON(address(0), 10*1e27);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of transferWSTON function should revert if insufficient balance
     */
    function testTransferWstonShouldRevertIfInsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert(TreasuryStorage.UnsuffiscientWstonBalance.selector);
        Treasury(treasuryProxyAddress).transferWSTON(user1, 100000000000000000000*1e27);
        vm.stopPrank();
    }

    // --------------------------- MINTNEWASSET FUNCTION ----------------------------

    /**
     * @notice tests the behavior of mintNewAssets function
     */
    function testMintAssetFromTreasury() public {
        vm.startPrank(owner);
        Treasury(treasuryProxyAddress).mintNewAssets(1,user1,1);
        uint256 balance = AssetFactory(assetfactoryProxyAddress).balanceOf(user1,1);
        assert(balance == 1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of minNewtAssets function if the caller is not the owner
     */
    function testMintNewAssetsShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        Treasury(treasuryProxyAddress).mintNewAssets(1,user1,1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of mintNewAssets function if the contract is paused
     */
    function testMintNewAssetsShouldRevertIfContractPaused() public {
        vm.startPrank(owner);
        Treasury(treasuryProxyAddress).pause();
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert("Pausable: paused");
        Treasury(treasuryProxyAddress).mintNewAssets(1,user1,1);
        vm.stopPrank();
    }

    /**
     * @notice tests the behavior of minNewtAssets function if the treasury does not hold enough WSTON
     */
    function testMintNewAssetsShouldRevertNotEnoughWstonInTreasury() public {
        vm.startPrank(owner);
        vm.expectRevert(TreasuryStorage.NotEnoughWstonAvailableInTreasury.selector);
        Treasury(treasuryProxyAddress).mintNewAssets(1,user1,10000000000000000000);
        vm.stopPrank();
    }

    // --------------------------- TRANSFERTREASURYTOKENSTO FUNCTION ----------------------------

    /**
     * @notice tests the behavior of transferTreasuryTokensTo function
     */
    function testTransferTreasuryTokensto() public {
        // mint new Asset to the treasury
        vm.startPrank(treasuryProxyAddress);
        vm.expectEmit(true, true, true, true);
        emit AssetFactoryStorage.NFTMinted(1,treasuryProxyAddress,1);
        AssetFactory(assetfactoryProxyAddress).mintAsset(1,treasuryProxyAddress,1);
        uint256 balance = AssetFactory(assetfactoryProxyAddress).balanceOf(treasuryProxyAddress,1);
        assert(balance == 1);
        vm.stopPrank();

        // transfer asset to user1
        vm.startPrank(owner);
        Treasury(treasuryProxyAddress).transferTreasuryTokensto(user1, 1, 1, "");
        assert(AssetFactory(assetfactoryProxyAddress).balanceOf(treasuryProxyAddress,1) == 0);
        assert(AssetFactory(assetfactoryProxyAddress).balanceOf(user1,1) == 1);
        vm.stopPrank();
    }

}