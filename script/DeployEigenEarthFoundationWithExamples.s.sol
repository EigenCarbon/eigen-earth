// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Saxon Nicholls <saxon@eigenearth.xyz>
// Made by Sax with ❤️ — because we only have one planet.
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";

contract DeployWithExamples is Script {
    function logBalance(EigenVintageCarbonCoin coin, address user, string memory label) internal view {
        console.log(label, coin.balanceOf(user));
    }

    function run(
        address landVerifierBeneficiary,
        uint256 landFee,
        address carbonVerifierBeneficiary,
        uint256 carbonFee,
         address landWallet,                        // Unused
        address carbonCoinCommissionBeneficiary
    ) external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // --- DEPLOY FOUNDATION ---
        EigenEarthFoundation foundation = new EigenEarthFoundation(
            deployer,
            landVerifierBeneficiary,
            landFee,
            carbonVerifierBeneficiary,
            carbonFee,
            carbonCoinCommissionBeneficiary
        );
       // EigenEarth earth = foundation.earth();
        EigenCarbonService carbonService = foundation.carbonService();

        // --- CREATE VINTAGES ---
        for (uint16 year = 2025; year <= 2030; year++) {
            carbonService.createVintageCoin(year);
        }

        // --- MINT MULTIPLE LAND ASSETS ---
        LandAsset memory asset1 = LandAsset("Rainforest A", "bafy1", "GEOJSON", 617700169958293500, 1_000_000, LandType.TropicalForest, 0, 1);
        LandAsset memory asset2 = LandAsset("Grassland B", "bafy2", "GEOJSON", 617700169958293501, 500_000, LandType.Grassland, 0, 1);
        LandAsset memory asset3 = LandAsset("Mangrove C", "bafy3", "GEOJSON", 617700169958293502, 750_000, LandType.Mangrove, 0, 1);


        // Auto-verify via foundation
        uint256 id1 = foundation.mint(deployer, deployer, asset1, 2025, 2027);
        uint256 id2 = foundation.mint(deployer, deployer, asset2, 2025, 2027);
        uint256 id3 = foundation.mint(deployer, deployer, asset3, 2025, 2027);

        // --- LOG BALANCES ---
        for (uint16 year = 2025; year <= 2027; year++) {
            EigenVintageCarbonCoin coin = carbonService.vintageCoin(year);
            logBalance(coin, deployer, string(abi.encodePacked("Deployer balance ", vm.toString(year))));
        }

        // --- BURN SOME COINS ON DIFFERENT LANDS/VINTAGES ---
        EigenVintageCarbonCoin coin2025 = carbonService.vintageCoin(2025);
        EigenVintageCarbonCoin coin2026 = carbonService.vintageCoin(2026);
        EigenVintageCarbonCoin coin2027 = carbonService.vintageCoin(2027);

        carbonService.burnCarbonCoins(deployer, 2025, id1, 100);
        carbonService.burnCarbonCoins(deployer, 2026, id2, 50);
        carbonService.burnCarbonCoins(deployer, 2027, id3, 75);

        console.log("Burned 100 on id1 2025");
        console.log("Burned 50 on id2 2026");
        console.log("Burned 75 on id3 2027");

        // --- FINAL BALANCES + ACCOUNTING CHECK ---
        logBalance(coin2025, deployer, "Final balance 2025:");
        logBalance(coin2026, deployer, "Final balance 2026:");
        logBalance(coin2027, deployer, "Final balance 2027:");

        console.log("Issued id1 2025:", carbonService.issued(id1, 2025));
        console.log("Burned id1 2025:", carbonService.burned(id1, 2025));

        console.log("Issued id2 2026:", carbonService.issued(id2, 2026));
        console.log("Burned id2 2026:", carbonService.burned(id2, 2026));

        console.log("Issued id3 2027:", carbonService.issued(id3, 2027));
        console.log("Burned id3 2027:", carbonService.burned(id3, 2027));

        vm.stopBroadcast();
    }
}
