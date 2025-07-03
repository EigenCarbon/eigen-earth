// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../EigenEarth.sol";
import "./EigenVintageCarbonCoin.sol";

struct Abatement {
    string metadataCid;         // Off chain meta data evidencing the request
    uint256 kgPerSqmPerYear;    // e.g. 3670e15 = 3.67 tonnes/year/sqm × 1e18
    bool    verified;           // Always false to start - except the default 
    uint64  timestamp;
}

contract EigenCarbonService is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
// Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant CARBON_VERIFIER_ROLE = keccak256("CARBON_VERIFIER_ROLE");
 
// State
    EigenEarth public earth;
    address admin;
    address foundation; // EigenCarbon Foundation

 /// @notice BaselineAbatement rates (kg CO₂/m²/yr ×1e18) per LandType
    mapping(LandType => uint256) public abatementBaseLine;

    mapping(uint256 => Abatement[]) public abatementHistory;

/// @notice Tracks issued and burned amounts of carbon coins: landTokenId => vintageYear => amount
    mapping(uint256 => mapping(uint16 => uint256)) public issued;
    mapping(uint256 => mapping(uint16 => uint256)) public burned;

 /// @notice Registry of vintageYear => CarbonCoin contract
    mapping(uint16 => EigenVintageCarbonCoin) public vintageCoin;
    uint16[] public supportedVintages;

/// @notice Commission settings
    address public commissionBeneficiary;
    uint16 public commissionBps = 500;       // 5% commission (500 basis points)
    uint16 public constant BPS_DENOM = 10000;

// Events
    event AbatementProposed(uint256 indexed tokenId, string metadataCid, uint256 kgPerSqmPerYear, address indexed proposer);
    event AbatementApproved(uint256 indexed tokenId, uint256 index, uint256 kgPerSqmPerYear, address indexed verifier);

    event CommissionAddressSet(address commissionAddress);
    event CommissionRateSet(uint16 commissionBps);

    event CarbonMinted(
        uint256 indexed landTokenId,
        uint16 indexed vintageYear,
        address indexed recipient,
        uint256 netAmount,
        uint256 timestamp
    );

     // Event to log the burn action
    event CarbonBurned(
        uint256 indexed landTokenId,
        uint16 indexed vintageYear,
        address indexed burner,
        uint256 amountBurned,
        uint256 timestamp
    );

    event VintageCoinCreated(uint16 vintageYear, address coinAddress);

    constructor(address earthAddress) {
        require(earthAddress != address(0), "Invalid NFT address");
        earth = EigenEarth(earthAddress);
        _disableInitializers();        
    }

    function initializeCarbonBaseline() internal 
    {
        // Initialize abatementBaseLine with carbon sequestration values in kg/m²/year
        // Convert kg/m²/year to tonnes/km²/year (1 tonne = 1000 kg, 1 km² = 1,000,000 m²)
        abatementBaseLine[LandType.TropicalForest]       = 1000e15; // 1 kg/m²/year = 1000 tonnes/km²/year
        abatementBaseLine[LandType.TemperateForest]      = 500e15;  // 0.5 kg/m²/year = 500 tonnes/km²/year
        abatementBaseLine[LandType.BorealForest]         = 200e15;  // 0.2 kg/m²/year = 200 tonnes/km²/year
        abatementBaseLine[LandType.Grassland]            = 100e15;  // 0.1 kg/m²/year = 100 tonnes/km²/year
        abatementBaseLine[LandType.HighIntensityFarming] = 50e15;   // 0.05 kg/m²/year = 50 tonnes/km²/year
        abatementBaseLine[LandType.LowIntensityFarming]  = 100e15;  // 0.1 kg/m²/year = 100 tonnes/km²/year
        abatementBaseLine[LandType.Agroforestry]         = 500e15;  // 0.5 kg/m²/year = 500 tonnes/km²/year
        abatementBaseLine[LandType.Mangrove]             = 1000e15; // 1 kg/m²/year = 1000 tonnes/km²/year
        abatementBaseLine[LandType.FreshwaterWetland]    = 500e15;  // 0.5 kg/m²/year = 500 tonnes/km²/year
        abatementBaseLine[LandType.Desert]               = 10e15;   // 0.01 kg/m²/year = 10 tonnes/km²/year
        abatementBaseLine[LandType.UrbanLand]            = 20e15;   // 0.02 kg/m²/year = 20 tonnes/km²/year
        abatementBaseLine[LandType.HighLatitudeOcean]    = 10e15;   // 0.01 kg/m²/year = 10 tonnes/km²/year
        abatementBaseLine[LandType.MidLatitudeOcean]     = 10e15;   // 0.01 kg/m²/year = 10 tonnes/km²/year
        abatementBaseLine[LandType.EquatorialOcean]      = 5e15;    // 0.005 kg/m²/year = 5 tonnes/km²/year
    }

    function initialize(
        address adminAddress,
        address foundationAddress,
        address earthAddress
    ) external initializer {
        require(adminAddress != address(0), "Admin cannot be zero");
        require(foundationAddress != address(0), "Foundation cannot be zero");
        require(earthAddress != address(0), "Invalid NFT address");
        require(address(earth) == address(0), "Earth already set - only set once - almost immutable");

        __UUPSUpgradeable_init();
        __AccessControl_init();

        admin = adminAddress;
        foundation = foundationAddress;
        earth = EigenEarth(earthAddress);
        commissionBps = 500; 

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, foundationAddress);

        _grantRole(MINTER_ROLE, adminAddress);
        _grantRole(MINTER_ROLE, foundationAddress);

        _grantRole(VERIFIER_ROLE, adminAddress);
        _grantRole(VERIFIER_ROLE, foundationAddress);

        _grantRole(CARBON_VERIFIER_ROLE, adminAddress);
        _grantRole(CARBON_VERIFIER_ROLE, foundationAddress);

        initializeCarbonBaseline();
    }

        // Should return kg / year
    function getCurrentCarbonAbatement(uint256 tokenId) public view returns (uint256) {
        require(earth.ownerOf(tokenId) != address(0), "Invalid token");
        
        LandAsset memory asset = earth.getLandAsset(tokenId);
        Abatement[] memory history = abatementHistory[tokenId];

        uint256 baselineKgPerSqmPerYear; 
        uint256 baselineAbateKg;

        if (history.length == 0) {
            baselineKgPerSqmPerYear = abatementBaseLine[asset.landType];
            baselineAbateKg = (asset.plotArea * baselineKgPerSqmPerYear) / 1e18;

            return baselineAbateKg;
        }

        // Search for most recent verified abatement
        for (uint i = history.length; i > 0; i--) {
            Abatement memory entry = history[i - 1];
           
            if (entry.verified) {
                uint256 abateKg = (asset.plotArea * entry.kgPerSqmPerYear) / 1e18;
                return abateKg;
            }
        }

        // No verified abatement found, fallback to baseline
        baselineKgPerSqmPerYear = abatementBaseLine[asset.landType];
        baselineAbateKg = (asset.plotArea * baselineKgPerSqmPerYear) / 1e18;

        return baselineAbateKg;
    }


    function proposeAbatement(
        uint256 tokenId,
        string calldata metadataCid,
        uint256 kgPerSqmPerYear
    ) external {
        require(kgPerSqmPerYear > 0, "Must be > 0");
        abatementHistory[tokenId].push(Abatement({
            metadataCid: metadataCid,
            kgPerSqmPerYear: kgPerSqmPerYear,
            verified: false,
            timestamp: uint64(block.timestamp)
        }));
        emit AbatementProposed(tokenId, metadataCid, kgPerSqmPerYear, msg.sender);
    }

   function approveLatestAbatement(uint256 tokenId) external onlyRole(CARBON_VERIFIER_ROLE) {
        uint256 length = abatementHistory[tokenId].length;
        require(length > 0, "No abatement proposals");

        Abatement storage abatement = abatementHistory[tokenId][length - 1];
        require(!abatement.verified, "Latest abatement already verified");

        abatement.verified = true;
        emit AbatementApproved(tokenId, length - 1, abatement.kgPerSqmPerYear, msg.sender);
    }

    /// @notice Set commission address
    function setCommissionAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addr != address(0), "Invalid address");
        commissionBeneficiary = addr;
        emit CommissionAddressSet(addr);
    }

    /// @notice Set commission rate in basis points (max 1000 = 10%)
    function setCommissionRate(uint16 bps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bps <= 1000, "Too high");
        commissionBps = bps;
        emit CommissionRateSet(bps);
    }

    function createVintageCoin(uint16 vintageYear) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        require(address(vintageCoin[vintageYear]) == address(0), "Vintage already exists");

        EigenVintageCarbonCoin coin = new EigenVintageCarbonCoin( admin, foundation, address(this), vintageYear );
        vintageCoin[vintageYear] = coin;
        supportedVintages.push(vintageYear);

        emit VintageCoinCreated(vintageYear, address(coin));
        return address(coin);
    }

    function mintCarbonCoins(
        uint256 landTokenId,
        uint16 vintageYear,
        address to
    ) external onlyRole(MINTER_ROLE) {
        require(to != address(0), "Invalid recipient");
        require(earth.ownerOf(landTokenId) != address(0), "Invalid land token");

        // Ensure vintage supported
        EigenVintageCarbonCoin coin = vintageCoin[vintageYear];
        require(address(coin) != address(0), "Unsupported vintage");

        // Get current abatement (kg)
        uint256 abatementKg = getCurrentCarbonAbatement(landTokenId);
      
        // Calculate allowable mint = abatementKg + burned - issued
        uint256 previouslyIssued = issued[landTokenId][vintageYear];
        uint256 previouslyBurned = burned[landTokenId][vintageYear];

        require(previouslyIssued < abatementKg + previouslyBurned, "All carbon for this land and vintage already issued");

        uint256 netAvailableKg = abatementKg + previouslyBurned - previouslyIssued;
        require(netAvailableKg > 0, "No carbon available");

        // Compute commission
        uint256 commissionKg = (netAvailableKg * commissionBps) / BPS_DENOM;
        uint256 netToRecipientKg = netAvailableKg - commissionKg;

        // Update state
        issued[landTokenId][vintageYear] += netAvailableKg;

        // Convert kg to ERC-20 units (18 decimals)
        uint256 netToRecipientTokens = netToRecipientKg * 1e18;
        uint256 commissionTokens = commissionKg * 1e18;

        // Mint coins
        coin.mint(to, netToRecipientTokens);
       
        if (commissionKg > 0 && commissionBeneficiary != address(0)) {
            coin.mint(commissionBeneficiary, commissionTokens);
         
        }

        emit CarbonMinted(landTokenId, vintageYear, to, netToRecipientKg, block.timestamp);
    }

 /// @notice Burn a specific amount of carbon coins linked to a landTokenId
 // NOTE: This function is safe against reentrancy because internal state is updated before external calls
    function burnCarbonCoins(
        address burner,
        uint16 vintageYear,
        uint256 landTokenId,
        uint256 amountToBurn
    ) public {
        require(burner != address(0), "Invalid burner");
        require(amountToBurn > 0, "Amount must be > 0");

        EigenVintageCarbonCoin coin = vintageCoin[vintageYear];
        require(address(coin) != address(0), "Vintage not supported");

        uint256 balance = coin.balanceOf(burner);
        require(balance >= amountToBurn, "Insufficient carbon coin balance");

        uint256 totalIssued = issued[landTokenId][vintageYear];
        uint256 totalBurned = burned[landTokenId][vintageYear];

        // Ensure burn does not exceed what was issued for this landTokenId + vintageYear
        require(totalBurned + amountToBurn <= totalIssued, "Burn exceeds issued amount");

        // Update burned amount
        burned[landTokenId][vintageYear] += amountToBurn;

        emit CarbonBurned(landTokenId, vintageYear, burner, amountToBurn, block.timestamp);

        // Burn tokens - minimise re-entrancy risk
        coin.burn(burner, amountToBurn);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

}

