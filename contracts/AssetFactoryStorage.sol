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
    uint256 public numberOfTokens;

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

    // mint Events
    event NFTMinted(uint256 tokenId, address to, uint256 numberOfNFTToMint);

    // burn Events
    event NFTBurnt(uint256 tokenId, address owner, uint256 numberOfNFTToBurn);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

    //---------------------------------------------------------------------------------------
    //-------------------------------------ERRORS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // setup errors
    error WrongNumberOfValues();

    // minting errors
    error AddressZero();
    error WrongNumberOfNFTToMint();
    error WrongTokenId();

    // tranfer errors
    error TransferFailed();
    
    // access errors
    error UnauthorizedCaller(address caller);
    error ContractPaused();
    error ContractNotPaused();
}