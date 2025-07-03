// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "../types/EigenTypes.sol";

interface IEigenEarth {
    function getH3Index(uint256 tokenId) external view returns (uint64);
    function getPlotArea(uint256 tokenId) external view returns (uint256);
    function getTitle(uint256 tokenId) external view returns (string memory);
    function getMetadataCid(uint256 tokenId) external view returns (string memory);
    function getLandAsset(uint256 tokenId) external view returns (LandAsset memory);
    function getLandUpdates(uint256 tokenId) external view returns (LandUpdate[] memory);
}


