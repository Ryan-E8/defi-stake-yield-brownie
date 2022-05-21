// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // Tells how many different tokens each address has
    mapping(address => uint256) public uniqueTokensStaked;
    // Maps each token to their associated price feed address
    mapping(address => address) public tokenPriceFeedMapping;
    // List of stakers
    address[] public stakers;
    // List of allowed tokens
    address[] public allowedTokens;
    // Will be set to the address of our Dapp token in the constructor
    IERC20 public dappToken;

    // stakeTokens - DONE!
    // unStakeTokens - DONE!
    // issueTokens - DONE!
    // addAllowedTokens - DONE!
    // getValue - DONE!

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    // Maps a token to it's price feed contract
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Loop through stakers list and give them rewards base on their total value locked
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            // Gets the total $ value of every token a user holds
            uint256 userTotalValue = getUserTotalValue(recipient);
            // We can call .transfer because TokenFarm will be the contract that holds all of the dapp tokens, transfer the user dappToken = to their total value
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    // Loop through all of the allowed tokens, check if they hold any by calling getUserSingleTokenValue() for each allowed token then adds up the total $ value
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            // Adds the $ value of each token a user holds to totalValue
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    // Get's the value of a single token a user holds by calling getTokenValue()
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // Get the price of the token
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return // returning the balace of a token that a user holds time it's price divided by decimals for maths sake
        ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    // Returns the price and decimals of the given token
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // Get's the price feed address of the token from our mapping
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    // Allows users to stake tokens that are on the allowed tokens list
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        // This interface IERC20(_token) gives us the ABI and address of the token
        // Transfering _amount from msg.sender to TokenFarm contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // If the user has not staked this token yet, then update their uniqueTokensStaked amount
        updateUniqueTokensStaked(msg.sender, _token);
        // stakingBalance of this token from msg.sender = their previous balance + amount
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // If this is the first unique token a user is staking, then add them to the stakers list
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    // Allows users to unstake all of their balance of a token
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    // Adds +1 to uniqueTokensStaked for that user if they do not have a balance of that token yet and they are staking a token
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // Allows the owner to add tokens to the allowedTokens array
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    // Will return 'True' if the token is allowed or 'False' if it is not
    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
