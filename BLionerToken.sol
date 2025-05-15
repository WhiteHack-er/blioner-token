// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BLionerToken {
    string public name = "BLioner";
    string public symbol = "BLNR";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    bool public paused;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public snapshotTaken;
    mapping(address => uint256) public snapshots;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notBlacklisted(address addr) {
        require(!blacklist[addr], "Blacklisted");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Snapshot(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
        uint256 initialSupply = 1_000_000_000 * 10 ** uint256(decimals);
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        maxTxAmount = initialSupply;       // по умолчанию нет лимитов
        maxWalletAmount = initialSupply;   // по умолчанию нет лимитов
    }

    function transfer(address to, uint256 amount) public notBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public notBlacklisted(msg.sender) returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public notBlacklisted(from) whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Allowance too low");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(amount <= maxTxAmount, "Exceeds max tx amount");
        require(balanceOf[to] + amount <= maxWalletAmount, "Exceeds wallet limit");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Not enough to burn");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function setBlacklist(address user, bool status) public onlyOwner {
        blacklist[user] = status;
    }

    function setWhitelist(address user, bool status) public onlyOwner {
        whitelist[user] = status;
    }

    function snapshot(address user) public onlyOwner {
        snapshots[user] = balanceOf[user];
        snapshotTaken[user] = true;
        emit Snapshot(user, snapshots[user]);
    }

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        maxTxAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        maxWalletAmount = amount;
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i], amounts[i]);
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}
