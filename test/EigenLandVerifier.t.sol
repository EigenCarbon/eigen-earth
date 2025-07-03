// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/EigenEarth.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/verifiers/EigenLandVerifier.sol";

contract EigenLandVerifierTest is Test {
    EigenEarth earth;
    EigenLandVerifier verifier;
    EigenEarthFoundation foundationContract;
    address admin = address(0x1);
    address foundation = address(0x2);
    address beneficiary = address(0x3);
    address user = address(0x4);

    uint256 fee = 1 ether;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy foundation (mimics production deployment)
        foundationContract = new EigenEarthFoundation(
            admin, // deployer / default admin
            beneficiary, // land verifier beneficiary
            fee, // land verification fee
            beneficiary, // carbon verifier beneficiary (re-use for simplicity in test)
            fee, // carbon verification fee
            foundation // carbon coin commission beneficiary
        );

        // Get deployed proxies / contracts
        earth = foundationContract.earth();
        verifier = foundationContract.landVerifier();

        vm.stopPrank();
    }

    function testAutoVerifyByAdmin() public {
        vm.startPrank(admin);
        uint256 tokenId = earth.mint(admin, _dummyAsset());
        verifier.requestVerification(tokenId);
        assertTrue(earth.isLandVerified(tokenId));
        vm.stopPrank();
    }

    function testAutoVerifyByFoundation() public {
        address foundationAddr = address(foundationContract);
        assertTrue(
            earth.hasRole(earth.LAND_VERIFIER_ROLE(), foundationAddr),
            "Foundation should have LAND_VERIFIER_ROLE"
        );

        vm.startPrank(foundationAddr);
        uint256 tokenId = earth.mint(foundationAddr, _dummyAsset());

        vm.expectEmit(true, true, true, true);
        //emit LandVerificationUpdated(tokenId, true, foundationAddr);

        verifier.requestVerification(tokenId);

        assertTrue(earth.landVerified(tokenId), "Land should be verified");
        vm.stopPrank();
    }

    function testRequestVerificationPaysFee() public {
        vm.deal(user, 2 ether);
        uint256 tokenId = earth.mint(user, _dummyAsset());

        uint256 preBalance = beneficiary.balance;
        vm.startPrank(user);
        verifier.requestVerification{value: fee}(tokenId);
        vm.stopPrank();

        uint256 postBalance = beneficiary.balance;
        assertEq(postBalance - preBalance, fee);
    }

    function testRequestVerificationFailsIfUnderpaid() public {
        vm.deal(user, 0.5 ether);
        uint256 tokenId = earth.mint(user, _dummyAsset());

        vm.startPrank(user);
        vm.expectRevert("Insufficient fee");
        verifier.requestVerification{value: 0.5 ether}(tokenId);
        vm.stopPrank();
    }

    function testSetFeeAndBeneficiary() public {
        vm.startPrank(admin);
        verifier.setFee(2 ether);
        assertEq(verifier.getFee(), 2 ether);

        verifier.setBeneficiary(user);
        assertEq(verifier.getBeneficiary(), user);
        vm.stopPrank();
    }

    function testSetVerified() public {
        vm.startPrank(admin);
        uint256 tokenId = earth.mint(admin, _dummyAsset());
        verifier.setVerified(tokenId, true, "test");
        assertTrue(earth.isLandVerified(tokenId));
        vm.stopPrank();
    }

    function _dummyAsset() internal pure returns (LandAsset memory) {
        return
            LandAsset({
                title: "Test",
                metadataCid: "bafybeicid",
                geojsonCid: "GEOJSON",
                h3Index: 1,
                plotArea: 1000,
                landType: LandType.TropicalForest,
                state: 0,
                version: 1
            });
    }
}
