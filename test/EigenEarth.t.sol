// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/EigenEarth.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EigenEarthTest is Test {
    EigenEarth public earth;
    address public admin;

    function setUp() public {
        admin = address(this);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(new EigenEarth()),
            abi.encodeWithSelector(
                EigenEarth.initialize.selector,
                "EigenEarth",
                "EARTH",
                admin,
                admin
            )
        );
        earth = EigenEarth(address(proxy));
    }

    function testMintQueryVerifyUpdateBurn() public {
        // Create LandAsset
        LandAsset memory asset = LandAsset({
            title: "Test Land",
            metadataCid: "bafybeib3g...test-meta",
            geojsonCid: "GEOJSON",
            h3Index: 617700169958293503,
            plotArea: 1000000,
            landType: LandType.TemperateForest,
            state: 0,
            version: 1
        });

        // Mint
        uint256 tokenId = earth.mint(admin, asset);
        assertEq(tokenId, 0); // first token id
        assertEq(earth.ownerOf(tokenId), admin);

        // Query individual getters
        assertEq(earth.getH3Index(tokenId), asset.h3Index);
        assertEq(earth.getPlotArea(tokenId), asset.plotArea);
        assertEq(earth.getTitle(tokenId), asset.title);
        assertEq(earth.getMetadataCid(tokenId), asset.metadataCid);

        // Query full struct
        LandAsset memory queried = earth.getLandAsset(tokenId);
        assertEq(queried.title, asset.title);
        assertEq(queried.metadataCid, asset.metadataCid);
        assertEq(queried.h3Index, asset.h3Index);
        assertEq(queried.plotArea, asset.plotArea);
        assertEq(queried.version, asset.version);
        assertEq(queried.state, asset.state);

        // Update
        earth.updateLandAsset(tokenId, "bafybeib3g...update1");
        LandUpdate[] memory updates = earth.getLandUpdates(tokenId);
        assertEq(updates.length, 1);
        assertEq(updates[0].metadataCid, "bafybeib3g...update1");
        assertFalse(updates[0].verified);

        // Verify land
        earth.setLandVerified(tokenId, true);
        assertTrue(earth.landVerified(tokenId));

        // Verify update
        earth.verifyLandUpdate(tokenId, 0, true);
        updates = earth.getLandUpdates(tokenId);
        assertTrue(updates[0].verified);

        // Burn
        earth.burn(tokenId);
        // OwnerOf should revert after burn
        vm.expectRevert(
            abi.encodeWithSignature("ERC721NonexistentToken(uint256)", tokenId)
        );
        earth.ownerOf(tokenId);

        // Post-burn check: no land asset
        LandAsset memory burnedAsset = earth.getLandAsset(tokenId);
        assertEq(burnedAsset.h3Index, 0);
        assertEq(burnedAsset.plotArea, 0);
        assertEq(bytes(burnedAsset.title).length, 0);
        assertEq(bytes(burnedAsset.metadataCid).length, 0);

        // Post-burn check: updates cleared
        updates = earth.getLandUpdates(tokenId);
        assertEq(updates.length, 0);

        // Post-burn check: verified reset
        assertFalse(earth.landVerified(tokenId));
    }
}
