// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "../interfaces/IVerifier.sol";
import "../services/carbon/EigenCarbonService.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

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

contract EigenCarbonVerifier is IVerifier, AccessControl {
    EigenCarbonService public immutable carbonService;

    address immutable private _admin;
    address immutable private _foundation;
    address private _beneficiary;
    uint256 private _feeWei;

    event CarbonVerificationRecorded(uint256 indexed tokenId, bool verified, string reason);
    event FeeUpdated(uint256 newFeeWei);
    event BeneficiaryUpdated(address newBeneficiary);

    constructor(
        address carbonServiceAddress, 
        address admin_, 
        address foundation_,
        address beneficiary_, 
        uint256 feeWei_) {
        require(carbonServiceAddress != address(0), "Invalid service address");
        require(admin_ != address(0), "Invalid admin");
        require(foundation_ != address(0), "Invalid foundation");
        require(beneficiary_ != address(0), "Invalid beneficiary");

        carbonService = EigenCarbonService(carbonServiceAddress);
       
        _admin = admin_;
        _foundation = foundation_;
        _beneficiary = beneficiary_;
        _feeWei = feeWei_;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _foundation);
    }

   function requestVerification(uint256 tokenId) external payable override {
        if (msg.sender != _admin && msg.sender != _foundation) {
            require(msg.value >= _feeWei, "Insufficient fee");
            payable(_beneficiary).transfer(msg.value);
            // Optionally emit event to track external requests
            emit CarbonVerificationRecorded(tokenId, false, "Verification requested by external user");
        } else {
            // Auto-verify immediately for admin/foundation
            carbonService.approveLatestAbatement(tokenId);
            emit CarbonVerificationRecorded(tokenId, true, "Auto-verified by foundation/admin");
        }
    }


    function setVerified(uint256 tokenId, bool verified, string calldata reason)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        carbonService.approveLatestAbatement(tokenId);
        emit CarbonVerificationRecorded(tokenId, verified, reason);
    }

    function setFee(uint256 feeWei_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeWei = feeWei_;
        emit FeeUpdated(feeWei_);
    }

    function getFee() external view override returns (uint256) {
        return _feeWei;
    }

    function setBeneficiary(address beneficiary_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beneficiary_ != address(0), "Invalid beneficiary");
        _beneficiary = beneficiary_;
        emit BeneficiaryUpdated(beneficiary_);
    }

    function getBeneficiary() external view override returns (address) {
        return _beneficiary;
    }
}

