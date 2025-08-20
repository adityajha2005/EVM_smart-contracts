// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "../src/Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Exchange} from "../src/Exchange.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract ExchangeTest is Test {
    using SafeERC20 for IERC20;
    
    Factory factory;
    Exchange exchange;
    MockToken token;
    
    address liquidityProvider;
    address trader;
    address user3;
    
    uint256 constant INITIAL_LIQUIDITY_ETH = 10 ether;
    uint256 constant INITIAL_LIQUIDITY_TOKENS = 1000 ether;
    uint256 constant TRADER_BALANCE = 5000 ether;

    function setUp() public {
        liquidityProvider = makeAddr("LP");
        trader = makeAddr("Trader");
        user3 = makeAddr("User3");
        
        factory = new Factory();
        token = new MockToken();

        address exchangeAddr = factory.createExchange(address(token));
        exchange = Exchange(payable(exchangeAddr));

        // Fund accounts
        token.transfer(liquidityProvider, INITIAL_LIQUIDITY_TOKENS);
        token.transfer(trader, TRADER_BALANCE);
        token.transfer(user3, TRADER_BALANCE);

        // Give accounts some ETH
        vm.deal(liquidityProvider, 100 ether);
        vm.deal(trader, 100 ether);
        vm.deal(user3, 100 ether);

        // Add initial liquidity
        vm.startPrank(liquidityProvider);
        token.approve(address(exchange), INITIAL_LIQUIDITY_TOKENS);
        exchange.addLiquidity{value: INITIAL_LIQUIDITY_ETH}(INITIAL_LIQUIDITY_TOKENS);
        vm.stopPrank();
    }

    // ============ CONSTRUCTOR TESTS ============
    
    function test_constructor() public {
        assertEq(exchange.tokenAddress(), address(token));
        assertEq(exchange.lpToken().exchange(), address(exchange));
    }

    function test_constructor_revert_zeroTokenAddress() public {
        vm.expectRevert();
        new Exchange(address(0));
    }

    // ============ INITIAL STATE TESTS ============
    
    function test_initialLiquidity() public {
        assertEq(token.balanceOf(address(exchange)),INITIAL_LIQUIDITY_TOKENS);
        assertEq(address(exchange).balance,INITIAL_LIQUIDITY_ETH);
        assertEq(exchange.lpToken().totalSupply(),sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS));
    }

    function test_initialLPTokenBalance() public {
        uint256 expectedLP = sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS);
        assertEq(exchange.lpToken().balanceOf(liquidityProvider),expectedLP);
    }

    // ============ ADD LIQUIDITY TESTS ============
    
    function test_addLiquidity_initial() public {
        uint256 additionalEth = 5 ether;
        uint256 additionalTokens = 500 ether;

        vm.startPrank(user3);
        token.approve(address(exchange), additionalTokens);
        uint256 lpMinted = exchange.addLiquidity{value:additionalEth}(additionalTokens);
        assertEq(lpMinted, sqrt(additionalEth * additionalTokens));
        assertEq(token.balanceOf(address(exchange)),INITIAL_LIQUIDITY_TOKENS + additionalTokens);
        assertEq(address(exchange).balance,INITIAL_LIQUIDITY_ETH + additionalEth);
        assertEq(exchange.lpToken().totalSupply(),sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS) + sqrt(additionalEth * additionalTokens));
        assertEq(exchange.lpToken().balanceOf(user3),sqrt(additionalEth * additionalTokens));
        vm.stopPrank();
    }

    function test_addLiquidity_insufficientTokenAmount() public {
        uint256 additionalEth = 5 ether;
        uint256 insufficientTokens = 100 ether;

        vm.startPrank(user3);
        token.approve(address(exchange), insufficientTokens);
        vm.expectRevert();
        exchange.addLiquidity{value:additionalEth}(insufficientTokens);
        vm.stopPrank();
    }

    function test_addLiquidity_events() public {
        uint256 additionalEth = 5 ether;
        uint256 additionalTokens = 500 ether;

        vm.startPrank(user3);
        token.approve(address(exchange), additionalTokens);
        vm.expectEmit(true, false, false, true);
        emit Exchange.AddLiquidity(user3, additionalEth, additionalTokens, sqrt(additionalEth * additionalTokens));
        exchange.addLiquidity{value: additionalEth}(additionalTokens);
        vm.stopPrank();
    }

    // ============ REMOVE LIQUIDITY TESTS ============
    
    function test_removeLiquidity() public {
        uint256 lpToRemove = sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS);
        vm.startPrank(liquidityProvider);
        exchange.lpToken().approve(address(exchange), lpToRemove);
        (uint256 ethReturned, uint256 tokenReturned) = exchange.removeLiquidity(lpToRemove);
        assertEq(ethReturned, INITIAL_LIQUIDITY_ETH);
        assertEq(tokenReturned, INITIAL_LIQUIDITY_TOKENS);
        assertEq(token.balanceOf(address(exchange)),0);
        assertEq(address(exchange).balance,0);
        assertEq(exchange.lpToken().totalSupply(),0);
        assertEq(exchange.lpToken().balanceOf(liquidityProvider),0);
        vm.stopPrank();
    }

    function test_removeLiquidity_zeroAmount() public {
        uint lpToRemove = 0;
        vm.startPrank(liquidityProvider);
        vm.expectRevert();
        exchange.removeLiquidity(lpToRemove);
        vm.stopPrank();
    }

    // function test_removeLiquidity_noLiquidity() public {
    //     uint256 lpToRemove = sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS);
    //     vm.startPrank(liquidityProvider);
    //     // vm.expectRevert();
    //     exchange.removeLiquidity(lpToRemove);
    //     vm.stopPrank();
    // }

    function test_removeLiquidity_events() public {
        uint256 lpToRemove = sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS);
        vm.startPrank(liquidityProvider);
        exchange.lpToken().approve(address(exchange), lpToRemove);
        vm.expectEmit(false, true, false, true);
        emit Exchange.RemoveLiquidity(liquidityProvider, INITIAL_LIQUIDITY_ETH, INITIAL_LIQUIDITY_TOKENS, lpToRemove);
        exchange.removeLiquidity(lpToRemove);
        vm.stopPrank();
    }

    // ============ SWAP TESTS ============
    
    function test_swapTokenForEth() public {
        uint256 tokenToSwap = 1 ether;
        uint256 minEth = 0.009 ether; 
        vm.startPrank(trader);
        token.approve(address(exchange),tokenToSwap);
        uint256 ethBought = exchange.swapTokenForEth(tokenToSwap, minEth);
        assertEq(ethBought, 9960069810399032); 
        assertEq(token.balanceOf(address(exchange)),INITIAL_LIQUIDITY_TOKENS + tokenToSwap);
        assertEq(address(exchange).balance,INITIAL_LIQUIDITY_ETH - ethBought);
        assertEq(exchange.lpToken().totalSupply(),sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS));
        assertEq(exchange.lpToken().balanceOf(trader),0);
        vm.stopPrank();
    }

    function test_swapTokenForEth_insufficientOutput() public {
        uint256 tokenToSwap = 1 ether;
        uint256 minEth = 1 ether; 
        vm.startPrank(trader);
        token.approve(address(exchange),tokenToSwap);
        vm.expectRevert();
        exchange.swapTokenForEth(tokenToSwap, minEth);
        vm.stopPrank();
    }

    function test_swapTokenForEth_zeroAmount() public {
        uint256 tokenToSwap = 0;
        uint256 minEth = 0.009 ether;
        vm.startPrank(trader);
        token.approve(address(exchange),tokenToSwap);
        vm.expectRevert();
        exchange.swapTokenForEth(tokenToSwap, minEth);
        vm.stopPrank();
    }

    function test_swapEthForToken() public {
        uint256 ethToSwap = 1.000000000000000001 ether;
        uint256 minTokens = 1 ether;
        vm.startPrank(trader);
        vm.deal(trader, ethToSwap);
        uint256 tokensBought = exchange.swapEthForToken{value: ethToSwap}(minTokens);
        assertEq(tokensBought, 83104109360673501778);
        assertEq(token.balanceOf(address(exchange)),INITIAL_LIQUIDITY_TOKENS - tokensBought);
        assertEq(address(exchange).balance,INITIAL_LIQUIDITY_ETH + ethToSwap);
        assertEq(exchange.lpToken().totalSupply(),sqrt(INITIAL_LIQUIDITY_ETH * INITIAL_LIQUIDITY_TOKENS));
        assertEq(exchange.lpToken().balanceOf(trader),0);
        vm.stopPrank();
    }

    function test_swapEthForToken_insufficientOutput() public {
        uint256 ethToSwap = 0.0000000000000001 ether;
        uint256 minTokens = 1 ether;
        vm.startPrank(trader);
        vm.deal(trader, ethToSwap);
        vm.expectRevert();
        exchange.swapEthForToken{value: ethToSwap}(minTokens);
        vm.stopPrank();
    }

    function test_swapEthForToken_zeroAmount() public {
        uint256 ethToSwap = 0 ether;
        uint256 minTokens = 0 ether;
        vm.startPrank(trader);
        vm.deal(trader, ethToSwap);
        vm.expectRevert();
        exchange.swapEthForToken{value: ethToSwap}(minTokens);
        vm.stopPrank();
    }

    // ============ GET AMOUNT OUT TESTS ============
    
    function test_getAmountOut() public {
        uint256 amountIn = 1 ether;
        uint256 inputReserve = 1 ether;
        uint256 outputReserve = 1 ether;
        uint256 finalAmount = exchange.getAmountOut(amountIn, inputReserve, outputReserve);
        assertEq(finalAmount,499248873309964947);
    }

    function test_getAmountOut_zeroInput() public {
        uint256 amountIn = 0;
        vm.expectRevert();
        exchange.getAmountOut(amountIn, 1 ether, 1 ether);
    }

    function test_getAmountOut_zeroInputReserve() public {
        uint256 amountIn = 1 ether;
        uint256 inputReserve = 0;
        uint256 outputReserve = 1 ether;
        vm.expectRevert();
        exchange.getAmountOut(amountIn, inputReserve, outputReserve);
    }

    function test_getAmountOut_zeroOutputReserve() public {
        uint256 amountIn = 1 ether;
        uint256 inputReserve = 1 ether;
        uint256 outputReserve = 0;
        vm.expectRevert();
        exchange.getAmountOut(amountIn, inputReserve, outputReserve);
    }

    // ============ GAS OPTIMIZATION TEST ============
    
    function test_gasUsage_addLiquidity() public {
        uint256 additionalEth = 5 ether;
        uint256 additionalTokens = 500 ether;
        vm.startPrank(user3);
        token.approve(address(exchange), additionalTokens);
        uint256 lpMinted = exchange.addLiquidity{value:additionalEth}(additionalTokens);
        assertEq(lpMinted, sqrt(additionalEth * additionalTokens));
        vm.stopPrank();
    }

    // ============ INTEGRATION TEST ============
    
    function test_completeTradingCycle() public {
        uint256 tokenToSwap = 1 ether;
        uint256 minEth = 0.009 ether;
        uint256 ethToSwap = 1 ether;
        uint256 minTokens = 1 ether;
        vm.startPrank(trader);
        token.approve(address(exchange),tokenToSwap);
        vm.deal(trader, ethToSwap);
        uint256 ethBought = exchange.swapTokenForEth(tokenToSwap, minEth);
        assertEq(ethBought, 9960069810399032);
        uint256 tokensBought = exchange.swapEthForToken{value: ethToSwap}(minTokens);
        assertEq(tokensBought, 83256333991724220316);
        vm.stopPrank();
    }

    // ============ HELPER FUNCTIONS ============
    
    function test_sqrt_function() public {
        uint256 ethAmount = 10 ether;
        uint256 tokenAmount = 1000 ether;
        uint256 product = ethAmount * tokenAmount;
        console.log("Product:", product);
        
        uint256 result = sqrt(product);
        console.log("Sqrt result:", result);
        
        assertGt(result, 0);
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
