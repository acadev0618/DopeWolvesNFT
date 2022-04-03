pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

/**
 * @title LoxarToken
 * @dev Very simple ERC20 Token example, where all 10000 tokens are pre-assigned to the creator.
 */
contract LoxarToken is ERC20 {
    string public constant NAME = "ERC-20 TOKEN ";
    string public constant SYMBOL = "ROSE-DW";
    uint8 public constant DECIMALS = 18;

    // Total Supply: 2.000.000
    uint256 public constant MAX_TOTAL_SUPPLY = 2000000 * (10 ** uint256(DECIMALS)); // 2000000 tokens
    // Max buy and Max Sale = 0.1% of total supply (2.000 LXR)
    uint256 public constant MAX_BUY_AMOUNT = 2000 * (10 ** uint256(DECIMALS)); // 2000 tokens

    // modify initial token supply
    uint256 private constant INITIAL_SUPPLY = 1000 * (10 ** uint256(DECIMALS)); // 100 tokens

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    mapping(address => uint256) private _buyTimeStamp;
    mapping(address => uint256) private _sellableBalances;

    constructor () public ERC20(NAME, SYMBOL) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 value) public payable returns (bool) {
        _mint(to, value);
        return true;
    }

    function mintFromGame(address to, uint256 value) public payable returns (bool) {
        _mint(to, value);
        _sellableBalances[to] += value;
        return true;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override{
        console.log("block.timestamp: ", block.timestamp);
        require(MAX_TOTAL_SUPPLY >= totalSupply() + amount, "ERC20: Max supply reached");
        require(MAX_BUY_AMOUNT >= amount, "ERC20: transfer amount exceeds max_buy and max_sale");
        require(buyedTimestamp(to) + 1 days <= block.timestamp, "ERC20: can't transfer, because set cooldown of 24hs between buys");
    }

    function _afterTokenTransfer(address from, address to,uint256 amount) internal virtual override{
        _buyTimeStamp[to] = block.timestamp;
    }

    function buyedTimestamp(address account) private returns (uint256) {
        return _buyTimeStamp[account];
    }

    function buyToken(address from, uint256 amount) public payable{
        address owner = _msgSender();
        if (from != address(0))
            _transfer(from, owner, amount);
       else
            _mint(owner, amount);

        emit Bought(amount);
    }

    function sellToken(address to, uint256 amount) public payable {
        address owner = _msgSender();
        console.log("sellableBalance[]: ", _sellableBalances[owner]);
        require(_sellableBalances[owner] >= amount, "LXR: transfer amount exceeds sellable balance");
        _transfer(owner, to, amount);
        emit Sold(amount);
    }
}
