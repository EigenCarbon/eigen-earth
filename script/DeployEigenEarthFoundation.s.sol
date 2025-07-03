// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/EigenEarthFoundation.sol";

contract DeployEigenEarthFoundation is Script {
    function run(
        address deployer,
        address landVerifierBeneficiary,
        uint256 landFee,
        address carbonVerifierBeneficiary,
        uint256 carbonFee,
        address landWallet,                        // Unused
        address carbonCoinCommissionBeneficiary
    ) external {
        // uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerKey);

        console.log("Deploying EigenEarthFoundation...");
        console.log("Deployer:", deployer);

        vm.startBroadcast();

        EigenEarthFoundation foundation = new EigenEarthFoundation(
            deployer,
            landVerifierBeneficiary,
            landFee,
            carbonVerifierBeneficiary,
            carbonFee,
            carbonCoinCommissionBeneficiary
        );

        // Create the coins via CarbonService
        EigenCarbonService carbonService = foundation.carbonService();
        address vintage2025Address = carbonService.createVintageCoin(2025);
        address vintage2026Address = carbonService.createVintageCoin(2026);
        address vintage2027Address = carbonService.createVintageCoin(2027);
        address vintage2028Address = carbonService.createVintageCoin(2028);
        address vintage2029Address = carbonService.createVintageCoin(2029);
        address vintage2030Address = carbonService.createVintageCoin(2030);

        // Log deployment details
        console.log("landVerifierBeneficiary :", address(landVerifierBeneficiary));
        console.log("landFee                  :", landFee);
        console.log("carbonVerifierBeneficiary:", address(carbonVerifierBeneficiary));
        console.log("carbonFee                :", carbonFee);
        console.log("carbonCoinCommissionBeneficiary:", address(carbonCoinCommissionBeneficiary));

        console.log("EigenEarthFoundation deployed at:", address(foundation));
        console.log("EigenEarth deployed at:", address(foundation.earth()));
        console.log("EigenCarbonService deployed at:", address(foundation.carbonService()));
        console.log("LandVerifier deployed at:", address(foundation.landVerifier()));
        console.log("CarbonVerifier deployed at:", address(foundation.carbonVerifier()));

        // Log vintage coin addresses
        console.log("Vintage 2025 Coin Address:", vintage2025Address);
        console.log("Vintage 2026 Coin Address:", vintage2026Address);
        console.log("Vintage 2027 Coin Address:", vintage2027Address);
        console.log("Vintage 2028 Coin Address:", vintage2028Address);
        console.log("Vintage 2029 Coin Address:", vintage2029Address);
        console.log("Vintage 2030 Coin Address:", vintage2030Address);

        vm.stopBroadcast();
    }
}

