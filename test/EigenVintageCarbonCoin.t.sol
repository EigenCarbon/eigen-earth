// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";

contract VintageCarbonCoinTest is Test {
    EigenVintageCarbonCoin public coin;
    address public admin;
    address public user;
    uint16 public constant VINTAGE_YEAR = 2025;

    function setUp() public {
        admin = address(this);
        user = vm.addr(1);
        coin = new EigenVintageCarbonCoin(admin, admin, admin, VINTAGE_YEAR);
    }

    function testDeploymentDetails() public {
        assertEq(coin.vintageYear(), VINTAGE_YEAR);
        assertEq(coin.name(), "EigenCarbon2025");
        assertEq(coin.symbol(), "EC2025");
    }

    function testCoinBeginAndEnd() public {
        uint256 begin = coin.CoinBegin();
        uint256 end = coin.CoinEnd();
        assertLt(begin, end, "Begin should be before end");
    }

    function testMintSuccess() public {
        uint256 amount = 1000 ether;
        coin.mint(user, amount);
        assertEq(coin.balanceOf(user), amount);
    }

    function testMintZeroAddress() public {
        vm.expectRevert("Zero address");
        coin.mint(address(0), 1000 ether);
    }

    function testMintZeroAmount() public {
        vm.expectRevert("Zero amount");
        coin.mint(user, 0);
    }

    function testBurnSuccess() public {
        uint256 amount = 500 ether;
        coin.mint(user, amount);
        coin.burn(user, amount);
        assertEq(coin.balanceOf(user), 0);
    }

    function testBurnZeroAddress() public {
        vm.expectRevert("Zero address");
        coin.burn(address(0), 1000 ether);
    }

    function testBurnZeroAmount() public {
        vm.expectRevert("Zero amount");
        coin.burn(user, 0);
    }

    function testBurnInsufficientBalance() public {
        coin.mint(user, 100 ether);
        vm.expectRevert("Insufficient balance");
        coin.burn(user, 200 ether);
    }

    function testMintAccessControl() public {
        vm.prank(user);  // user is not minter
        vm.expectRevert();  // AccessControl revert
        coin.mint(user, 1000 ether);
    }

    function testBurnAccessControl() public {
        vm.prank(user);  // user is not minter
        vm.expectRevert();
        coin.burn(user, 100 ether);
    }

    function testEventsEmitted() public {
        vm.expectEmit(true, true, false, true);
        emit EigenVintageCarbonCoin.CoinsMinted(user, 123, block.timestamp);
        coin.mint(user, 123);

        coin.mint(user, 100); // Mint extra to burn

        vm.expectEmit(true, true, false, true);
        emit EigenVintageCarbonCoin.CoinsBurned(user, 100, block.timestamp);
        coin.burn(user, 100);
    }
}




