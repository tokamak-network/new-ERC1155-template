// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title AssetFactoryStorage Contract 
 * @author TOKAMAK OPAL TEAM
 * @notice This contract manages storage variables related to the ERC1155 token used by the AssetFactory
 * It is used for the creation of ERC1155 tokens, transfer of tokens or even specific customized interactions implemented.
**/
contract AssetFactoryStorage {
    
    //---------------------------------------------------------------------------------------
    //--------------------------------------STRUCT-------------------------------------------
    //---------------------------------------------------------------------------------------
    
    struct Asset {
        // add any additionnal features here
        uint256 tokenId;
        uint256 wstonValuePerNFT; // 27 decimals
        uint256 totalWstonValue; // 27 decimals
        string uri;
    }

    //---------------------------------------------------------------------------------------
    //-------------------------------------STORAGE-------------------------------------------
    //---------------------------------------------------------------------------------------

    Asset[] public Assets;
    mapping(uint256 => string) _uris;

    bool public paused;

    // contract addresses
    address internal wston;
    address internal treasury;

    //---------------------------------------------------------------------------------------
    //-------------------------------------EVENTS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // Premining events
    event Created(
        uint256 indexed tokenId, 
        uint256 wstonValue,
        string uri 
    );
    event TransferNFT(address from, address to, uint256 tokenId);

    // melt even
    event NFTMelted(uint256 tokenId, address owner);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

    //---------------------------------------------------------------------------------------
    //-------------------------------------ERRORS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // minting errors
    error MismatchedArrayLengths();
    error AddressZero();
    error NotNFTOwner();
    error WrongNumberOfNFTToMint();

    // Transfer error
    error SameSenderAndRecipient();
    error TransferFailed();

    // access errors
    error UnauthorizedCaller(address caller);
    error ContractPaused();
    error ContractNotPaused();
    error URIQueryForNonexistentToken(uint256 tokenId);
}