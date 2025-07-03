// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/services/carbon/EigenCarbonService.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";

contract EigenCarbonServiceDoubleMintTest is Test {
    EigenEarthFoundation internal foundation;
    EigenEarth internal earth;
    EigenCarbonService internal carbonService;

    address internal deployer;
    address internal landVerifierBeneficiary = address(0x1);
    address internal carbonVerifierBeneficiary = address(0x2);
    address internal carbonCoinCommissionBeneficiary = address(0x3);

    uint256 internal constant landFee = 0;
    uint256 internal constant carbonFee = 0;
    uint16 internal constant VINTAGE = 2025;

    address internal user = address(0xC);

    function setUp() public {
        // Simulate a deployer account
        deployer = address(this);

        // Deploy the foundation (which sets up everything)
        foundation = new EigenEarthFoundation(
            deployer,
            landVerifierBeneficiary,
            landFee,
            carbonVerifierBeneficiary,
            carbonFee,
            carbonCoinCommissionBeneficiary
        );

        // Pull out references
        earth = foundation.earth();
        carbonService = foundation.carbonService();

        // Admin creates the vintage
        carbonService.createVintageCoin(VINTAGE);

        // Mint and auto-verify land via foundation
        LandAsset memory asset = LandAsset({
            title: "Test Land",
            metadataCid: "bafyTest",
            geojsonCid: "GEOJSON",
            h3Index: 123456789,
            plotArea: 1000,
            landType: LandType.TropicalForest,
            state: 0,
            version: 1
        });
        foundation.mint(user, user, asset, VINTAGE, VINTAGE);
    }

    function testPreventDoubleMint() public {
        uint256 tokenId = 0;  // Since foundation.mint assigns tokenId 0 first

        // Check issued amount matches abatement
        uint256 abatement = carbonService.getCurrentCarbonAbatement(tokenId);
        uint256 issued = carbonService.issued(tokenId, VINTAGE);
        assertEq(issued, abatement, "Should have issued full abatement");

        // Second mint should fail
        vm.expectRevert("All carbon for this land and vintage already issued");
        carbonService.mintCarbonCoins(tokenId, VINTAGE, user);
    }
}
