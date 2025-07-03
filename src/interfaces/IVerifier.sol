// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

/// @title IVerifier
/// @notice Standard interface for verifiers (land, carbon, biodiversity, etc.)
interface IVerifier {
    /// @notice Request verification; user pays fee here.
    /// @param tokenId The asset ID (e.g. NFT) to verify.
    function requestVerification(uint256 tokenId) external payable;

    /// @notice Verifier records result of verification.
    /// @param tokenId The asset ID being verified.
    /// @param verified True if verified, false if rejected.
    /// @param reason Plaintext or CID with reason/context.
    function setVerified(uint256 tokenId, bool verified, string calldata reason) external;

    /// @notice Set the standard verification fee.
    /// @param feeWei Fee in wei.
    function setFee(uint256 feeWei) external;

    /// @notice Get the standard verification fee.
    /// @return The fee in wei.
    function getFee() external view returns (uint256);

    /// @notice Set the beneficiary that receives fees.
    /// @param beneficiary Address that receives the funds.
    function setBeneficiary(address beneficiary) external;

    /// @notice Get the current fee beneficiary.
    /// @return The beneficiary address.
    function getBeneficiary() external view returns (address);
}

// This standardises how verifiers interact across land, carbon, biodiversity etc.