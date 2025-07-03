// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./types/EigenTypes.sol";
import "./interfaces/IEigenEarth.sol";

/**
 * @title EigenCarbon Core Contracts
 * @notice These contracts are designed to be reentrancy-safe by design.
 * @dev Design rationale:
 * - External calls are strictly limited to:
 *   - OpenZeppelin audited contracts (e.g. ERC20, ERC721, AccessControl, Proxy).
 *   - Our own EigenCarbon ecosystem contracts, where upgrade paths are controlled
 *     and no fallback or reentrant entry points are exposed.
 * - No external call chains create circular dependencies that could enable reentrancy.
 * - Return values from external calls are either checked or not relied upon where critical.
 * - As a result, ReentrancyGuard is intentionally omitted throughout the system
 *   to minimize gas costs and bytecode size.
 * 
 * ⚠ NOTE: This rationale applies to the current design. Any future changes involving
 * new external calls or upgradeable contract targets should revisit this decision.
 */

contract EigenEarth is
    Initializable,
    ERC721Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
// Roles
    bytes32 public constant LAND_MINTER_ROLE = keccak256("LAND_MINTER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant LAND_VERIFIER_ROLE = keccak256("LAND_VERIFIER_ROLE");

// State
    address admin;
    address foundation;
    uint256 private tokenCounter;
    mapping(uint256 => LandAsset) public landAssets;
    mapping(uint256 => LandUpdate[]) public landUpdates;
    mapping(uint256 => bool) public landVerified;

// Events
    event LandAssetMinted(
        address indexed to,
        uint256 indexed tokenId,
        string title,
        uint64 h3Index,
        uint256 timestamp
    );

/// @notice Emitted when a LandAsset is updated
    event LandAssetUpdated(
        uint256 indexed tokenId,
        string metadataCid,
        uint256 timestamp
    );

/// @notice Emitted when land verification status changes
    event LandVerificationUpdated(
        uint256 indexed tokenId,
        bool verified,
        address indexed verifier
    );

 /// @notice Emitted when a LandAsset NFT is burned
    event LandAssetBurned(uint256 indexed tokenId, address indexed previousOwner);

    event LandUpdateAdded(
        uint256 indexed tokenId,
        string metadataCid,
        uint256 timestamp,
        uint256 updateIndex
    );

    event LandUpdateVerified(
        uint256 indexed tokenId,
        uint256 indexed updateIndex,
        bool verified,
        address indexed verifier
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name,
        string calldata symbol,
        address adminAddress,
        address foundationAddress
    ) external initializer {
        __ERC721_init(name, symbol);
        __UUPSUpgradeable_init();
        __AccessControl_init();

        require(adminAddress != address(0), "admin cannot be zero");
        require(foundationAddress != address(0), "foundation cannot be zero");

        admin = adminAddress;
        foundation = foundationAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, foundationAddress);

        _grantRole(LAND_MINTER_ROLE, adminAddress);
        _grantRole(LAND_MINTER_ROLE, foundationAddress);

        _grantRole(VERIFIER_ROLE, adminAddress);
        _grantRole(VERIFIER_ROLE, foundationAddress);

        _grantRole(LAND_VERIFIER_ROLE, adminAddress);
        _grantRole(LAND_VERIFIER_ROLE, foundationAddress);
    }

    function getFoundation() external view returns (address) {
        return foundation;
    }

    function getAdmin() external view returns (address) {
        return admin;
    }

    modifier onlyOwnerOrMinterRole() {
        require(
            hasRole(LAND_MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not owner or minter"
        );
        _;
    }

    modifier onlyOwnerOrVerifierRole() {
        require(
            hasRole(VERIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not owner or verifier"
        );
        _;
    }

    modifier onlyOwnerOrLandVerifierRole() {
        require(
            hasRole(LAND_VERIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not owner or land verifier"
        );
        _;
    }

    function landExists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /// @notice Check if a land asset is verified
    /// @param tokenId The ID of the land token
    /// @return True if verified, false otherwise
    function isLandVerified(uint256 tokenId) external view returns (bool) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landVerified[tokenId];
    }

    /// @notice Mint a new EigenEarth LandAsset NFT with auto-generated tokenId
    /// @param to The address to receive the NFT
    /// @param asset The LandAsset metadata to store on chain
    /// @return tokenId The minted token ID

    // Anyone can mint an NFT - it will not be verified
    function mint(
        address to,
        LandAsset calldata asset
    ) external  returns (uint256 tokenId) {
        require(to != address(0), "Invalid recipient");

        // Generate token ID
        tokenId = tokenCounter;
        tokenCounter++;

        // Mint the NFT
        _mint(to, tokenId);

        // Store the land asset metadata
        landAssets[tokenId] = asset;
        landVerified[tokenId] = false;

        emit LandAssetMinted(to, tokenId, asset.title, asset.h3Index, block.timestamp);
    }

    /// @notice Burn (destroy) a Land NFT and clean up associated metadata
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");

        require(
            msg.sender == owner ||
            hasRole(LAND_MINTER_ROLE, msg.sender) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not owner, minter, or admin"
        );

        // Burn the token
        _burn(tokenId);

        // Clean up associated metadata
        delete landAssets[tokenId];
        delete landUpdates[tokenId];
        delete landVerified[tokenId];

        emit LandAssetBurned(tokenId, owner);
    }

    /// @notice Append an update to an existing LandAsset
    /// @param tokenId The ID of the token to update
    /// @param metadataCid The off-chain metadata CID or URI describing the update
    function updateLandAsset(
        uint256 tokenId,
        string calldata metadataCid
    ) external onlyOwnerOrVerifierRole() {
        require(landExists(tokenId), "Token does not exist");
      
        landUpdates[tokenId].push(
            LandUpdate({
                timestamp: block.timestamp,
                metadataCid: metadataCid,
                verified: false             // Every update starts unverified
            })
        );

         emit LandUpdateAdded(tokenId, metadataCid, block.timestamp, landUpdates[tokenId].length - 1);
    }

    /// @notice Set the land verification status for a token
    /// @param tokenId The ID of the token
    /// @param verified True if land is verified, false otherwise
    function setLandVerified(uint256 tokenId, bool verified) external onlyOwnerOrLandVerifierRole() {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
       
        landVerified[tokenId] = verified;

        emit LandVerificationUpdated(tokenId, verified, msg.sender);
    }

    function verifyLandUpdate(
        uint256 tokenId,
        uint256 updateIndex,
        bool isVerified
    ) external {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        require(
            hasRole(LAND_VERIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not land verifier or admin"
        );
        require(updateIndex < landUpdates[tokenId].length, "Invalid update index");

        landUpdates[tokenId][updateIndex].verified = isVerified;

        emit LandUpdateVerified(tokenId, updateIndex, isVerified, msg.sender);
    }

    /// @notice Get the H3 index of a land asset
    function getH3Index(uint256 tokenId) external view returns (uint64) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landAssets[tokenId].h3Index;
    }

    /// @notice Get the plot area of a land asset
    function getPlotArea(uint256 tokenId) external view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landAssets[tokenId].plotArea;
    }

    /// @notice Get the full land asset struct
    function getLandAsset(uint256 tokenId) external view returns (LandAsset memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landAssets[tokenId];
    }

    /// @notice Get the update history for a land asset
    function getLandUpdates(uint256 tokenId) external view returns (LandUpdate[] memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landUpdates[tokenId];
    }
    /// @notice Get the title of a land asset
    function getTitle(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landAssets[tokenId].title;
    }

    /// @notice Get the metadata CID of a land asset
    function getMetadataCid(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return landAssets[tokenId].metadataCid;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

