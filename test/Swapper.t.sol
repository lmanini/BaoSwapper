// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interfaces/IUniswapV2Router.sol";
import "../src/interfaces/IERC20.sol";
import "../src/interfaces/Swapper.sol";

contract SwapTest is Test {
    IUniswapV2Router router;
    IERC20 baoV1;
    IERC20 baoV2;
    WETH weth;
    Swapper swapper;

    address payable sender;

    function setUp() external {
        router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        vm.label(address(router), "router");
        baoV1 = IERC20(0x374CB8C27130E2c9E04F44303f3c8351B9De61C1);
        vm.label(address(baoV1), "baoV1");
        baoV2 = IERC20(0xCe391315b414D4c7555956120461D21808A69F3A);
        vm.label(address(baoV2), "baoV2");
        weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        swapper = Swapper(0x235b30088E66d2D28F137b422B9349fBa51E0248);
        vm.label(address(swapper), "Swapper");

        sender = payable(address(uint160(uint256(keccak256(abi.encodePacked("sender"))))));
        vm.label(sender, "Sender");
        vm.deal(sender, 10 ether);
    }

    function testSwap() external {

        vm.startPrank(sender);

        // deposit weth
        payable(address(weth)).call{value: 1 ether}("");
        assertEq(weth.balanceOf(sender), 1 ether);

        // buy bao v1
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(baoV1);
        weth.approve(address(router), 1 ether);
        router.swapExactTokensForTokens(1 ether, 0, path, sender, type(uint256).max);

        assertLt(weth.balanceOf(sender), 1 ether);
        assertGt(baoV1.balanceOf(sender), 0);

        // convert v1 to v2
        uint256 myV1Bal = baoV1.balanceOf(sender);
        emit log_named_decimal_uint("V1 Bal before migration", myV1Bal, baoV1.decimals());

        baoV1.approve(address(swapper), myV1Bal);
        swapper.convertV1(sender, myV1Bal);

        uint256 myV2Bal = baoV2.balanceOf(sender);
        emit log_named_decimal_uint("V2 Bal after migration", myV2Bal, baoV2.decimals());

        // sell v2
        path[0] = address(baoV2);
        path[1] = address(weth);
        baoV2.approve(address(router), myV2Bal);
        router.swapExactTokensForTokens(myV2Bal, 0, path, sender, type(uint256).max);

        myV2Bal = baoV2.balanceOf(sender);
        assertEq(myV2Bal, 0);
        uint256 myWethBal = weth.balanceOf(sender);
        assertGt(myWethBal, 1 ether);

        vm.stopPrank();
    }
}



