
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { AssetFactoryStorage } from "../AssetFactoryStorage.sol";

interface IAssetFactory {
    struct Asset {
        // add any additionnal features here
        uint256 tokenId;
        uint256 wstonValuePerNFT; // 27 decimals
        uint256 totalWstonValue; // 27 decimals
        string uri;
    }

    function mintAsset(uint256 _tokenId, address _to, uint256 _numberOfNFTToMint) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

    function getAssetsSupplyTotalValue() external view returns(uint256 totalValue);

    function getApproved(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function getAsset(uint256 tokenId) external view returns (Asset memory);

    function getSpecificAssetWstonValue(uint256 _tokenId) external view returns (uint256);

}