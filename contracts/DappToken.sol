pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20 {
    constructor() public ERC20("Dapp Token", "DAPP") {
        // Initial supply of 1 million (+18 zeros)
        _mint(msg.sender, 1000000000000000000000000);
    }
}
