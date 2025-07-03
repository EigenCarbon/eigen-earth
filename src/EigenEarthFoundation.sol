// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "./EigenEarth.sol";
import "./services/carbon/EigenCarbonService.sol";
import "./verifiers/EigenLandVerifier.sol";
import "./verifiers/EigenCarbonVerifier.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title EigenEarthFoundation
/// @notice Central deployment + configuration contract for EigenEarth ecosystem.
contract EigenEarthFoundation is AccessControl {
    // Roles
    bytes32 public constant FOUNDATION_ADMIN_ROLE = keccak256("FOUNDATION_ADMIN_ROLE");

    // State
    EigenEarth immutable public earth;
    EigenCarbonService immutable public carbonService;
    EigenLandVerifier immutable public landVerifier;
    EigenCarbonVerifier immutable public carbonVerifier;

    address immutable public foundationAdmin;

    // Events
    event Deployed(
        address indexed earth,
        address indexed carbonService,
        address indexed landVerifier,
        address carbonVerifier
    );
    event MintedLand(uint256 indexed tokenId, address beneficiary);
    event LandAutoVerified(uint256 indexed tokenId);
    event VintageCreated(uint16 indexed year, address coinAddress);
    event CarbonIssued(uint256 indexed tokenId, uint16 indexed year, address beneficiary);
    event VerifierAppointed(address indexed verifier, string verifierType);
    event VerifierRemoved(address indexed verifier, string verifierType);

    constructor(
        address admin,
        address landVerifierBeneficiary,
        uint256 landFee,
        address carbonVerifierBeneficiary,
        uint256 carbonFee,
        address carbonCoinCommissionBeneficiary
    ) {
        require(admin != address(0), "Admin cannot be zero");
        require(landVerifierBeneficiary != address(0), "Invalid land verifier beneficiary");
        require(carbonVerifierBeneficiary != address(0), "Invalid carbon verifier beneficiary");
        require(carbonCoinCommissionBeneficiary != address(0), "Invalid commission beneficiary");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FOUNDATION_ADMIN_ROLE, admin);

        foundationAdmin = admin;

        // Deploy EigenEarth
        EigenEarth logic = new EigenEarth();
        bytes memory initData = abi.encodeWithSelector(
            EigenEarth.initialize.selector,
            "EigenEarth",
            "EARTH",
            admin,
            address(this)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(logic), initData);
        earth = EigenEarth(address(proxy));

        // Deploy EigenCarbonService
        EigenCarbonService carbonLogic = new EigenCarbonService(address(earth));
        bytes memory carbonInit = abi.encodeWithSelector(
            EigenCarbonService.initialize.selector,
            admin,
            address(this),
            address(earth)
        );
        ERC1967Proxy carbonProxy = new ERC1967Proxy(address(carbonLogic), carbonInit);
        carbonService = EigenCarbonService(address(carbonProxy));

        carbonService.setCommissionAddress(carbonCoinCommissionBeneficiary);

        // Deploy Land Verifier
        landVerifier = new EigenLandVerifier(address(earth), admin, address(this), landVerifierBeneficiary, landFee);
      
        // Deploy Carbon Verifier
        carbonVerifier = new EigenCarbonVerifier(address(carbonService), admin, address(this), carbonVerifierBeneficiary, carbonFee);
    
        // Grant roles
        earth.grantRole(earth.LAND_VERIFIER_ROLE(), address(landVerifier));
        carbonService.grantRole(carbonService.CARBON_VERIFIER_ROLE(), address(carbonVerifier));

        emit Deployed(address(earth), address(carbonService), address(landVerifier), address(carbonVerifier));
    }

    function mint(
        address landBeneficiary,
        address carbonBeneficiary,
        LandAsset calldata asset,
        uint16 startYear,
        uint16 endYear
    ) external returns (uint256 landTokenId){
        require(landBeneficiary != address(0), "Invalid land beneficiary");
        require(carbonBeneficiary != address(0), "Invalid carbon beneficiary");
        require(startYear <= endYear, "Invalid year range");

        // 1️⃣ Mint land NFT
        uint256 tokenId = earth.mint(landBeneficiary, asset);
        emit MintedLand(tokenId, landBeneficiary);

        // 2️⃣ Auto-verify land via landVerifier (no fee)
        landVerifier.setVerified(tokenId, true, "Foundation auto-verification");
        emit LandAutoVerified(tokenId);

        // 3️⃣ For each vintage year
        for (uint16 year = startYear; year <= endYear; year++) {
            // Ensure vintage coin exists
            if (address(carbonService.vintageCoin(year)) == address(0)) {
                carbonService.createVintageCoin(year);
                emit VintageCreated(year, address(carbonService.vintageCoin(year)));
            }

            // Mint carbon coins - use Baseline logic
            carbonService.mintCarbonCoins(tokenId, year, carbonBeneficiary);
            emit CarbonIssued(tokenId, year, carbonBeneficiary);
        }
        return tokenId;
    }

    // ========================
    // Verifier appointment / removal
    // ========================

    function grantVerifierRole(bytes32 role, address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(verifier != address(0), "Invalid address");
        _grantRole(role, verifier);
    }

    function revokeVerifierRole(bytes32 role, address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(verifier != address(0), "Invalid address");
        _revokeRole(role, verifier);
    }

    function appointLandVerifier(address verifier) external onlyRole(FOUNDATION_ADMIN_ROLE) {
        require(verifier != address(0), "Invalid verifier");
        earth.grantRole(earth.LAND_VERIFIER_ROLE(), verifier);
        emit VerifierAppointed(verifier, "Land");
    }

    function removeLandVerifier(address verifier) external onlyRole(FOUNDATION_ADMIN_ROLE) {
        earth.revokeRole(earth.LAND_VERIFIER_ROLE(), verifier);
        emit VerifierRemoved(verifier, "Land");
    }

    function appointCarbonVerifier(address verifier) external onlyRole(FOUNDATION_ADMIN_ROLE) {
        require(verifier != address(0), "Invalid verifier");
        carbonService.grantRole(carbonService.CARBON_VERIFIER_ROLE(), verifier);
        emit VerifierAppointed(verifier, "Carbon");
    }

    function removeCarbonVerifier(address verifier) external onlyRole(FOUNDATION_ADMIN_ROLE) {
        carbonService.revokeRole(carbonService.CARBON_VERIFIER_ROLE(), verifier);
        emit VerifierRemoved(verifier, "Carbon");
    }

    function createVintage(uint16 vintageYear) external onlyRole(FOUNDATION_ADMIN_ROLE) {
        carbonService.createVintageCoin(vintageYear);
    }
}
