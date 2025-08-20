    //SPDX-License-Identifier: MIT
    pragma solidity ^0.8.29;

    import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
    import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
    import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
    using SafeERC20 for IERC20;

    contract LPToken is ERC20 {

        address public exchange;

        modifier onlyExchange() {
            require(msg.sender == address(exchange), "Only exchange can call this function");
            _;
        }
        constructor(string memory name, string memory symbol, address _exchange) ERC20(name, symbol) {
            exchange = _exchange;
        }

        function mint(address to, uint256 amount) external onlyExchange {
            _mint(to, amount);
        }

        function burn(address from, uint256 amount) external onlyExchange{
            _burn(from, amount);
        }
    }

    contract Exchange is ReentrancyGuard {
        
    address public tokenAddress; //erc20 token paired with eth
    LPToken public lpToken;  

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        tokenAddress = _token;
        lpToken = new LPToken("LPToken", "LP", address(this));
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

        event AddLiquidity(address indexed user, uint256 ethAmount, uint256 tokenAmount, uint256 liquidityMinted);
        event RemoveLiquidity(address indexed user, uint256 ethAmount, uint256 tokenAmount, uint256 lpAmount);

    function addLiquidity(uint256 _amount) external payable nonReentrant returns (uint256) {
        uint256 ethAmount = msg.value;
        uint256 tokenReserve = IERC20(tokenAddress).balanceOf(address(this));
        uint256 ethReserve = address(this).balance - ethAmount;

        uint256 liquidityMinted;
            if(lpToken.totalSupply() == 0) {
                IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
                liquidityMinted = sqrt(ethAmount * _amount);
                lpToken.mint(msg.sender, liquidityMinted);
                emit AddLiquidity(msg.sender, ethAmount, _amount, liquidityMinted);
            } 
            else{
                //maintain the same ratio of eth to token
                uint256 requiredTokens = ethAmount * tokenReserve / ethReserve;
                require(_amount >= requiredTokens, "Insufficient token amount");
                IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), requiredTokens);
                liquidityMinted = (ethAmount * lpToken.totalSupply()) / ethReserve;
                lpToken.mint(msg.sender, liquidityMinted);
                emit AddLiquidity(msg.sender, ethAmount, requiredTokens, liquidityMinted);
            }
        return liquidityMinted;
    }

    function removeLiquidity(uint256 _lpAmount) external nonReentrant returns (uint256, uint256) {
            require(_lpAmount > 0, "Invalid LP amount");
            uint256 totalLP = lpToken.totalSupply();
            require(totalLP > 0, "No liquidity in the pool");
            uint256 ethAmount = (_lpAmount * address(this).balance) / totalLP;
            uint256 tokensToReturn = (_lpAmount * IERC20(tokenAddress).balanceOf(address(this))) / totalLP;
            // _burn(msg.sender, _lpAmount);
            lpToken.burn(msg.sender, _lpAmount);
            payable(msg.sender).transfer(ethAmount);
            IERC20(tokenAddress).safeTransfer(msg.sender, tokensToReturn);
            emit RemoveLiquidity(msg.sender, ethAmount, tokensToReturn, _lpAmount);
            return (ethAmount, tokensToReturn);
    }

    event TokenToEthSwap(address indexed user, uint256 tokensSold, uint256 ethBought);
    event EthToTokenSwap(address indexed user, uint256 ethSold, uint256 tokensBought);

    function getAmountOut(uint256 _amountIn, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(_amountIn > 0 && inputReserve > 0 && outputReserve > 0, "Invalid reserves/amount");
        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    function swapTokenForEth(uint256 _tokenSold, uint256 _minEth) external nonReentrant returns (uint256 ethBought) {
        require(_tokenSold > 0, "Zero tokens sold");
        uint256 tokenReserve = IERC20(tokenAddress).balanceOf(address(this));
        uint256 ethReserve = address(this).balance;

        ethBought = getAmountOut(_tokenSold, tokenReserve, ethReserve);
        require(ethBought >= _minEth && ethBought > 0, "Insufficient output amount");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenSold);

        (bool sent, ) = payable(msg.sender).call{value: ethBought}("");
        require(sent, "ETH transfer failed");

        emit TokenToEthSwap(msg.sender, _tokenSold, ethBought);
        return ethBought;
    }

    function swapEthForToken(uint256 _minTokens) external payable nonReentrant returns (uint256 tokensBought) {
        uint256 ethSold = msg.value;
        require(ethSold > 0, "Zero ETH sent");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = IERC20(tokenAddress).balanceOf(address(this));
        tokensBought = getAmountOut(ethSold, ethReserve, tokenReserve);
        require(tokensBought >= _minTokens && tokensBought > 0, "Insufficient output amount");

        IERC20(tokenAddress).safeTransfer(msg.sender, tokensBought);

        emit EthToTokenSwap(msg.sender, ethSold, tokensBought);
        return tokensBought;
    }

}