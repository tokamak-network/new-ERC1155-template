// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {AssetFactoryStorage} from "./AssetFactoryStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./proxy/ProxyStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns (bool);
    function transferTreasuryNFTto(address _to, uint256 _tokenId) external returns (bool);
}

/**
 * @title AssetFactory
 * @author TOKAMAK OPAL TEAM
 * @dev The AssetFactory contract is responsible for managing the lifecycle of ERC1155 tokens within the system.
 * This includes the creation, transfer, and brun of Assets. The contract provides functionalities
 * for both administrative and user interactions, ensuring a comprehensive management of asset tokens.
 *
 * Administrative Functions
 * - create Assets: Allows administrators to create and allocate Assets directly to the treasury contract.
 *   The purpose is to initialize the system with a predefined set of Assets that can be distributed or sold later.
 *
 * User Functions
 * - Burn Assets: Users can convert their Assets back into their underlying value.
 *   This process involves burning the asset token and transferring its value to the user.
 *
 * Security and Access Control
 * - The contract implements access control mechanisms to ensure that only authorized users can perform certain actions.
 *   For example, only the contract owner or designated administrators can premine Assets.
 * - The contract also includes mechanisms to pause and unpause operations, providing an additional layer of security
 *   in case of emergencies or required maintenance.
 *
 * Integration
 * - The AssetFactory contract integrates with other components of the system, such as the treasury and marketplace contracts,
 *   to facilitate seamless interactions and transactions involving Assets.
 */

contract AssetFactory is ProxyStorage,
    Initializable,
    ERC1155Upgradeable,
    AssetFactoryStorage,
    OwnableUpgradeable,
    ReentrancyGuard {

    /**
     * @notice Modifier to ensure the contract is not paused.
     */

    modifier whenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }

    /**
     * @notice Modifier to ensure the contract is paused.
     */
    modifier whenPaused() {
        if (!paused) {
            revert ContractNotPaused();
        }
        _;
    }

    /**
     * @notice Modifier to ensure the caller is the treasury contract
     */
    modifier onlyTreasury() {
        if (msg.sender != treasury) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the contract with the given parameters.
     * @param _owner Address of the contract owner.
     * @param _wston Address of the WSTON token.
     * @param _treasury Address of the treasury contract.
     */
    function initialize(
        address _owner, 
        address _wston, 
        address _treasury,
        uint256[] memory wstonValues,
        string[] memory uris
    ) external initializer {
        __ERC1155_init("");
        __Ownable_init(_owner);
        wston = _wston;
        treasury = _treasury;
        for(uint256 i = 0; i < wstonValues.length; i++) {
            createAsset(wstonValues[i], uris[i]);
        }
    }

    /**
     * @notice Sets the treasury address.
     * @param _treasury The new treasury address.
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice updates the wston token address
     * @param _wston New wston token address.
     */
    function setWston(address _wston) external onlyOwner {
        wston = _wston;
    }

    /**
     * @notice updates the wston value associated with each tokenId
     * @param wstonValues New wston values array.
     */
    function setWstonValuesAssociatedWtihTokenIds(uint256[] memory wstonValues) external onlyOwner {
        for(uint256 i = 0; i < wstonValues.length; i++) {
            Assets[i].wstonValuePerNFT = wstonValues[i];
        }
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice mints a new NFT for a specific token ID
     * @param _tokenId ID of the token to mint.
     * @param _to beneficiary of the NFT
     * @param _numberOfNFTToMint number of NFT to mint
     * @dev The caller must be the treasury.
     */
    function mintAsset(uint256 _tokenId, address _to, uint256 _numberOfNFTToMint) external whenNotPaused onlyTreasury {
        // reverts if wrong number of NFT to mint
        if(_numberOfNFTToMint == 0) {
            revert WrongNumberOfNFTToMint();
        }
        // Check if the recipient's address is zero
        if (_to == address(0)) {
            revert AddressZero();
        }
        
        // updates storage
        uint256 wstonValueOfNFTs = Assets[_tokenId].wstonValuePerNFT * _numberOfNFTToMint;
        Assets[_tokenId].totalWstonValue += wstonValueOfNFTs;
        // mint the NFT
        _mint(_to, _tokenId, _numberOfNFTToMint, "");
        emit NFTMinted(_tokenId, _to, _numberOfNFTToMint);
    }

    /**
     * @notice burns an asset token, converting it back to its value.
     * @param _tokenId ID of the token to melt.
     * @dev The caller receives the WSTON amount associated with the NFT.
     * @dev The ERC1155 token is burned.
     * @dev The caller must be the token owner.
     */
    function burnAsset(uint256 _tokenId, uint256 _numberOfNFTToBurn) external whenNotPaused {
        // Check if the caller's address is zero
        if (msg.sender == address(0)) {
            revert AddressZero();
        }

        //updates storage
        uint256 totalWstonValueToTransfer = Assets[_tokenId].wstonValuePerNFT * _numberOfNFTToBurn;
        Assets[_tokenId].totalWstonValue -= totalWstonValueToTransfer;

        // Burn the ERC1155 token
        _burn(msg.sender, _tokenId, _numberOfNFTToBurn);
        // Transfer the WSTON amount to the caller
        if (!ITreasury(treasury).transferWSTON(msg.sender, totalWstonValueToTransfer)) {
            revert TransferFailed();
        }
        // Emit an event indicating the NFT has been melted
        emit NFTBurnt(_tokenId, msg.sender, _numberOfNFTToBurn);
    }

    /**
     * @notice Creates a new ERC1155 type of NFT.
     * @param _wstonValue WSTON value of the new NFT to be created.
     * @param _uri TokenURI of the NFT.
     * @return The IDs of the newly created NFT.
     */
    function createAsset(uint256 _wstonValue, string memory _uri)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        uint256 newAssetId = Assets.length - 1;
        // Create the new NFT and get its ID
        Asset memory newAsset = Asset({
            tokenId: newAssetId,
            wstonValuePerNFT: _wstonValue,
            totalWstonValue: 0,
            uri: _uri
        });
        Assets.push(newAsset);

        // Emit an event for the creation of the new NFT
        emit Created(newAssetId, _wstonValue, _uri);
        return newAssetId;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------PRIVATE/INERNAL FUNCTIONS------------------------------------
    //---------------------------------------------------------------------------------------


    /**
     * @notice Checks if the recipient address can handle ERC1155 tokens.
     * @dev Calls the onERC1155Received function on the recipient if it is a contract.
     * @param from The address sending the token.
     * @param to The address receiving the token.
     * @param tokenId The ID of the token being transferred.
     * @param data Additional data with no specified format.
     */
    function _checkOnERC1155(address from, address to, uint256 tokenId, uint256 value, bytes memory data) private {
        // Check if the recipient is a contract
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(_msgSender(), from, tokenId, value, data) returns (bytes4 retval) {
                // Ensure the recipient contract returns the correct value
                if (retval != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                // Handle the case where the recipient contract does not implement the interface correctly
                if (reason.length == 0) {
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Retrieves the details of a specific NFT by its token ID.
     * @param _tokenId The ID of the NFT to retrieve.
     * @return The NFT struct containing details of the specified NFT.
     */
    function getAsset(uint256 _tokenId) public view returns (Asset memory) {
        return Assets[_tokenId];
    }

    /**
     * @notice Retrieves the total supply of NFT tokens.
     * @return The total number of NFT tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        // Return the total number of Assets, excluding the zero index
        return Assets.length - 1;
    }

    function getSpecificAssetWstonValue(uint256 _tokenId) external view returns (uint256) {
        return Assets[_tokenId].wstonValuePerNFT;
    }

    /**
     * @notice Calculates the total value of all Assets in supply.
     * @return totalValue The cumulative value of all Assets.
     */
    function getAssetsSupplyTotalValue() external view returns (uint256 totalValue) {
        uint256 Assetslength = Assets.length;

        // Sum the values of all Assets to get the total supply value
        for (uint256 i = 0; i < Assetslength; ++i) {
            totalValue += Assets[i].totalWstonValue;
        }
    }

    /**
     * @notice returns the uri associated with a specific tokenId
     */
    function uri(uint256 _tokenId) public view override returns(string memory) {
        return Assets[_tokenId].uri;
    }

    //---------------------------------------------------------------------------------------
    //-------------------------------STORAGE GETTERS-----------------------------------------
    //---------------------------------------------------------------------------------------

    function getTreasuryAddress() external view returns (address) {
        return treasury;
    }

    function getWstonAddress() external view returns (address) {
        return wston;
    }
}