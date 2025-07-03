// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VintageCarbonCoin
 * @notice A minimalistic ERC20 carbon credit token for a specific vintage year.
 * 
 * @dev This contract represents carbon credits issued for a given vintage (year).
 * 
 * Design choices:
 * 
 * - **One contract per vintage year**:
 *   Each deployed VintageCarbonCoin contract represents all fungible carbon credits for a single vintage (e.g. 2025).
 *   All tokens in this contract are interchangeable (ERC20 fungibility preserved), regardless of the originating land.
 * 
 * - **No per-token metadata or land linkage**:
 *   To keep the ERC20 standard fully intact and DeFi-friendly, the contract itself carries no on-chain information 
 *   about which land generated a particular token. Provenance is instead managed by an external contract 
 *   (e.g. CarbonServices) or off-chain indexers.
 * 
 * - **Auto-generated token name and symbol**:
 *   The contract name and symbol are derived automatically from the vintage year to ensure consistency and reduce 
 *   deployment errors. For example, vintage year 2025 will produce:
 *     - Name: EigenCarbonCoin2025
 *     - Symbol: CC2025
 * 
 * - **Simple mint/burn API with access control**:
 *   Minting and burning are restricted to addresses with the MINTER_ROLE. The contract emits dedicated 
 *   CoinsMinted and CoinsBurned events to support off-chain tracking of carbon issuance and retirement.
 * 
 * - **Time window helpers**:
 *   CoinBegin() and CoinEnd() functions provide the start and end timestamps for the vintage period (midnight UTC 
 *   June 30 of the prior year to June 30 of the vintage year). This can be used by external systems to enforce 
 *   vintage-specific business logic.
 * 
 * This design keeps the ERC20 carbon token "dumb" by intention:
 * - Provenance, verification, commission, and compliance logic reside outside this contract (e.g. in CarbonServices).
 * - This ensures maximum compatibility with wallets, exchanges, DeFi protocols, and indexers.
 */


contract EigenVintageCarbonCoin is ERC20, AccessControl {
    using Strings for uint256;

    bytes32 public constant CARBON_MINTER_ROLE = keccak256("CARBON_MINTER_ROLE");

    uint16 public immutable vintageYear;

    event CoinsMinted(address indexed to, uint256 amount, uint256 timestamp);
    event CoinsBurned(address indexed from, uint256 amount, uint256 timestamp);

    constructor(
        address admin,
        address foundation,
        address carbonService,
        uint16 _vintageYear
    )
        ERC20(
            string.concat("EigenCarbon", uint256(_vintageYear).toString()),
            string.concat("EC", uint256(_vintageYear).toString())
        )
    {
        vintageYear = _vintageYear;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CARBON_MINTER_ROLE, admin);

        _grantRole(DEFAULT_ADMIN_ROLE, foundation);
        _grantRole(CARBON_MINTER_ROLE, foundation);

        _grantRole(DEFAULT_ADMIN_ROLE, carbonService);
        _grantRole(CARBON_MINTER_ROLE, carbonService);
    }

    function mint(address to, uint256 amount) external onlyRole(CARBON_MINTER_ROLE) {
        require(to != address(0), "Zero address");
        require(amount > 0, "Zero amount");
        _mint(to, amount);
        emit CoinsMinted(to, amount, block.timestamp);
    }

    function burn(address from, uint256 amount) external onlyRole(CARBON_MINTER_ROLE) {
        require(from != address(0), "Zero address");
        require(amount > 0, "Zero amount");
        require(balanceOf(from) >= amount, "Insufficient balance");
        _burn(from, amount);
        emit CoinsBurned(from, amount, block.timestamp);
    }

    function CoinBegin() public view returns (uint256) {
        return _timestampFromDate(vintageYear - 1, 6, 30);
    }

    function CoinEnd() public view returns (uint256) {
        return _timestampFromDate(vintageYear, 6, 30);
    }

    function _isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) return false;
        if (year % 100 != 0) return true;
        return (year % 400 == 0);
    }

    function _timestampFromDate(uint16 year, uint8 month, uint8 day) internal pure returns (uint256 timestamp) {
        for (uint16 y = 1970; y < year; y++) {
            timestamp += _isLeapYear(y) ? 366 days : 365 days;
        }
        uint8[12] memory md = [31,28,31,30,31,30,31,31,30,31,30,31];
        if (_isLeapYear(year)) md[1] = 29;
        for (uint8 m = 1; m < month; m++) {
            timestamp += md[m - 1] * 1 days;
        }
        timestamp += uint256(day - 1) * 1 days;
    }
}

