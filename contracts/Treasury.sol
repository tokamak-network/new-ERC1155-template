// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAssetFactory } from "./interfaces/IAssetFactory.sol"; 
import { AssetFactoryStorage } from "./AssetFactoryStorage.sol";
import { AuthControl } from "./common/AuthControl.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { TreasuryStorage } from "./TreasuryStorage.sol"; 
import "./proxy/ProxyStorage.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IMarketPlace {
    function putNFTListForSale(uint256[] memory tokenIds, uint256[] memory prices) external;
    function putNFTForSale(uint256 _tokenId, uint256 _price) external;
    function buyNFT(uint256 _tokenId, bool _paymentMethod) external;
    function removeNFTForSale(uint256 _tokenId) external;
}

interface IWstonSwapPool {
    function swapTONforWSTON(uint256 tonAmount) external;
}

/**
 * @title Treasury Contract for Token managememnt
 * @author TOKAMAK OPAL TEAM
 * @notice This contract manages the storage and transfer of NFT tokens and WSTON tokens within the ecosystem.
 * It facilitates interactions with the assetFactory, Marketplace, Random Pack, and Airdrop contracts.
 * The contract includes functionalities for creating premined NFTs, handling token transfers, and managing sales on the marketplace.
 * @dev The contract integrates with external interfaces for NFT creation, marketplace operations, and token swaps.
 * It includes security features such as pausing operations and role-based access control.
 */
contract Treasury is ProxyStorage, IERC721Receiver, ReentrancyGuard, AuthControl, TreasuryStorage {
    using SafeERC20 for IERC20;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------INITIALIZE FUNCTIONS-----------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the Treasury contract with the given parameters.
     * @param _wston Address of the WSTON token.
     * @param _assetFactory Address of the NFT factory contract.
     */
    function initialize(address _wston, address _assetFactory) external {
        require(!initialized, "already initialized");   
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        assetFactory = _assetFactory;
        wston = _wston;
        initialized = true;
    }

     /**
     * @notice Sets the address of the NFT factory.
     * @param _assetFactory New address of the NFT factory contract.
     */
    function setassetFactory(address _assetFactory) external onlyOwnerOrAdmin {
        _checkNonAddress(assetFactory);
        assetFactory = _assetFactory;
    }

    /**
     * @notice updates the wston token address
     * @param _wston New wston token address
     */
    function setWston(address _wston) external onlyOwner {
        wston = _wston;
    }

    /**
     * @notice Approves a specific operator to manage a NFT token.
     * @param operator Address of the operator.
     * @param _tokenId ID of the token to approve.
     */
    function approveNFT(address operator, uint256 _tokenId) external onlyOwnerOrAdmin {
        IAssetFactory(assetFactory).approve(operator, _tokenId);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------EXTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Transfers WSTON tokens to a specified address.
     * @param _to Address to transfer WSTON tokens to.
     * @param _amount Amount of WSTON tokens to transfer.
     * @dev only the assetFactory, MarketPlace, RandomPack, Airdrop or the Owner are authorized to transfer the funds
     * @return bool Returns true if the transfer is successful.
     */
    function transferWSTON(address _to, uint256 _amount) external onlyOwner nonReentrant returns(bool) {
        // check _to diffrent from address(0)
        _checkNonAddress(_to);

        // check the balance of the treasury
        uint256 contractWSTONBalance = getWSTONBalance();
        if(contractWSTONBalance < _amount) {
            revert UnsuffiscientWstonBalance();
        }

        // transfer to the recipient
        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    /**
     * @notice mints a new NFT for a specific token ID
     * @param _tokenId ID of the token to mint.
     * @param _to beneficiary of the NFT
     * @param _numberOfNFTToMint number of NFT to mint
     * @dev The caller must be the contract owner.
     */
    function mintNewAssets( 
        uint256 _tokenId,
        address _to,
        uint256 _numberOfNFTToMint
    ) external onlyOwner {
        // safety check for WSTON solvency
        if(getWSTONBalance() < IAssetFactory(assetFactory).getAssetsSupplyTotalValue() + (IAssetFactory(assetFactory).getSpecificAssetWstonValue(_tokenId) * _numberOfNFTToMint)) {
            revert NotEnoughWstonAvailableInTreasury();
        }

        // we create the NFTs from the assetFactory
        IAssetFactory(assetFactory).mintAsset(
            _tokenId,
            _to,
            _numberOfNFTToMint
        );
    }


    /**
     * @notice Transfers a NFT from the treasury to a specified address.
     * @param _to Address to transfer the NFT to.
     * @param _tokenId ID of the NFT token to transfer.
     * @dev only the assetFactory, MarketPlace, RandomPack, Airdrop or the Owner are able to transfer NFTs from the treasury
     * @return bool Returns true if the transfer is successful.
     */
    function transferTreasuryNFTto(address _to, uint256 _tokenId) external onlyOwner returns(bool) {
        IAssetFactory(assetFactory).transferFrom(address(this), _to, _tokenId);
        return true;
    }

    /**
     * @notice Handles the receipt of an ERC721 token.
     * @return bytes4 Returns the selector of the onERC721Received function.
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------INTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Checks if the provided address is a non-zero address.
     * @param account Address to check.
     */
    function _checkNonAddress(address account) internal pure {
        if(account == address(0))   revert InvalidAddress();
    }

    //---------------------------------------------------------------------------------------
    //------------------------STORAGE GETTER / VIEW FUNCTIONS--------------------------------
    //---------------------------------------------------------------------------------------

    // Function to check the balance of WSTON token within the contract
    function getWSTONBalance() public view returns (uint256) {
        return IERC20(wston).balanceOf(address(this));
    }

    function getAssetFactoryAddress() external view returns (address) {return assetFactory;}
    function getWstonAddress() external view returns(address) {return wston;}

}