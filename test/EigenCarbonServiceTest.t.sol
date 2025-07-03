// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/services/carbon/EigenCarbonService.sol";
import "../src/EigenEarth.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";

contract EigenCarbonServiceTest is Test {
    EigenEarthFoundation internal foundation;
    EigenCarbonService carbonService;
    EigenEarth earth;

    address admin = address(0xA);
    // address foundation = address(0xB);
    address user = address(0xC);

    address internal deployer = address(this);

    uint16 internal constant vintageYear = 2025;

    function setUp() public {
        foundation = new EigenEarthFoundation(
            deployer,
            address(0x1), // land verifier beneficiary
            0,
            address(0x2), // carbon verifier beneficiary
            0,
            address(0x3) // carbon commission beneficiary
        );

        earth = foundation.earth();
        carbonService = foundation.carbonService();

        carbonService.grantRole(carbonService.DEFAULT_ADMIN_ROLE(), admin);
        carbonService.grantRole(carbonService.MINTER_ROLE(), admin);
        carbonService.grantRole(carbonService.VERIFIER_ROLE(), admin);
        carbonService.grantRole(carbonService.CARBON_VERIFIER_ROLE(), admin);
    }

    function testInitializeBaseline() public {
        uint256 tropicalBaseline = carbonService.abatementBaseLine(
            LandType.TropicalForest
        );
        assertEq(tropicalBaseline, 1000e15);
    }

    function testCreateVintageCoin() public {
        vm.startPrank(admin);
        address coinAddr = carbonService.createVintageCoin(2025);
        assertTrue(coinAddr != address(0));
        assertEq(address(carbonService.vintageCoin(2025)), coinAddr);
        vm.stopPrank();
    }

    function testSetCommissionBeneficiary() public {
        vm.startPrank(admin);
        carbonService.setCommissionAddress(user);
        assertEq(carbonService.commissionBeneficiary(), user);
        vm.stopPrank();
    }

    function testSetCommissionAddress() public {
        vm.startPrank(admin);
        carbonService.setCommissionAddress(user);
        assertEq(carbonService.commissionBeneficiary(), user);
        vm.stopPrank();
    }

    function testSetCommissionRate() public {
        vm.startPrank(admin);
        carbonService.setCommissionRate(500);
        assertEq(carbonService.commissionBps(), 500);
        vm.expectRevert("Too high");
        carbonService.setCommissionRate(1001);
        vm.stopPrank();
    }

    function testOneCoinEqualsOneKg() public {
        vm.startPrank(admin);

        // Create the vintage coin first
        carbonService.createVintageCoin(vintageYear);

        // Mint a land asset with known plotArea
        LandAsset memory asset = LandAsset({
            title: "Test Land",
            metadataCid: "ipfs-test-meta",
            geojsonCid: "ipfs-geojson",
            h3Index: 123456,
            plotArea: 1000,  // 1000 m2
            landType: LandType.TropicalForest,
            state: 0,
            version: 1
        });

        uint256 tokenId = earth.mint(user, asset);

        // Mint carbon coins
        carbonService.mintCarbonCoins(tokenId, vintageYear, user);

        // Get balance
        EigenVintageCarbonCoin coin = carbonService.vintageCoin(vintageYear);
        uint256 balance = coin.balanceOf(user);

        // The TropicalForest baseline is 1000e15 kg/m2/year = 1 kg/m2/year
        // plotArea 1000m2 → 1000 kg abatement - fter commission 
        assertEq(balance, 950 * 1e18, "1 coin should equal 1 kg of carbon");
    }

    function testMintAndBurnFlow() public {
        // Setup
        vm.startPrank(admin);
        carbonService.createVintageCoin(2025);
        vm.stopPrank();

        // Mock a land asset
        vm.startPrank(admin);
        LandAsset memory asset = LandAsset({
            title: "Test",
            metadataCid: "cid",
            geojsonCid: "GEOJSON",
            h3Index: 0,
            plotArea: 1000000,
            landType: LandType.TropicalForest,
            state: 0,
            version: 1
        });
        uint256 tokenId = earth.mint(user, asset);
        carbonService.proposeAbatement(tokenId, "cid", 1500e15);
        carbonService.approveLatestAbatement(tokenId);
        vm.stopPrank();

        // Mint carbon coins
        carbonService.mintCarbonCoins(tokenId, 2025, user);
        uint256 issued = carbonService.issued(tokenId, 2025);
        assertGt(issued, 0);

        // Burn
        EigenVintageCarbonCoin coin = carbonService.vintageCoin(2025);
        uint256 balBefore = coin.balanceOf(user);
        carbonService.burnCarbonCoins(user, 2025, tokenId, 100);
        uint256 balAfter = coin.balanceOf(user);
        assertEq(balBefore - balAfter, 100);
        uint256 burned = carbonService.burned(tokenId, 2025);
        assertEq(burned, 100);
    }
}
