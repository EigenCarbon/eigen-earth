// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

enum LandType {
    TropicalForest,
    TemperateForest,
    BorealForest,
    Grassland,
    HighIntensityFarming,
    LowIntensityFarming,
    Agroforestry,
    Mangrove,
    FreshwaterWetland,
    Desert,
    UrbanLand,
    HighLatitudeOcean,
    MidLatitudeOcean,
    EquatorialOcean
}

struct LandUpdate {
    uint256 timestamp;
    string metadataCid; // typically a small metadata string or CID/URI
    bool verified;
}

/// @notice The core on-chain data for each token inside EigenEarthNFT.landAssets[tokenId]
struct LandAsset {
    string title; // On chain description
    string metadataCid; // Off chain meta data
    string geojsonCid;     // Pinata/IPFS CID for raw GeoJSON geometry
    uint64 h3Index; // For fast indexing
    uint256 plotArea; // measured in m²
    LandType landType; // e.g. [TropicalForest, TemperateForest, etc.]
    uint32 state; // State machine - future proof
    uint16 version; // Version future proof
}
