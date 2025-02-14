// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {console} from "../lib/forge-std/src/Test.sol";
contract ERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _nonces;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private _owner;
    bool private _pause;

    event logAddress(address owner);

    constructor(string memory name_, string memory symbols_) {
        _name = name_;
        _symbol = symbols_;
        _owner = msg.sender;
        _totalSupply = 200 ether;
        _balances[_getOwner()] = _totalSupply;
        _pause = false;
    }

    modifier onlyOwner() {
        require(_getOwner() == msg.sender, "Only Owner");
        _;
    }

    modifier whenNotPaused() {
        require(_pause == false, "Stop when pause");
        _;
    }

    function transfer(address to, uint256 amount) public {
        address owner = msg.sender;
        _tranfser(owner, to, amount);
    }
    function transferFrom(address from, address to, uint256 amount) public {
        address spender = msg.sender;
        uint256 fromAllowance = _allowances[from][spender];
        require(amount <= fromAllowance, "Not encough allowance");
        _tranfser(from, to, amount);
    }

    function _tranfser(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused {
        uint256 fromBalance = _balances[from];
        require(amount <= fromBalance, "low balance");
        _balances[from] -= amount;
        _balances[to] += amount;
    }

    function approve(address spender, uint256 amount) public {
        address owner = msg.sender;
        _approve(owner, spender, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return (_allowances[owner][spender]);
    }

    function pause() public onlyOwner {
        _pause = true;
    }

    function _toTypedDataHash(bytes32 hash_) public pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", hash_));
        return (digest);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "The deadline has expired");
        // nonce 값이 현재 소유자 논스와 일치해야 함
        // owner와 서명 값이 일치해야 함
        bytes32 hash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                _nonces[owner],
                deadline
            )
        );
        address signer = ecrecover(_toTypedDataHash(hash), v, r, s);
        require(owner != address(0), "Address is not zero");
        require(signer == owner, "INVALID_SIGNER");
        _approve(owner, spender, value);
        _nonces[owner] += 1;
    }

    function nonces(address owner) external view returns (uint256) {
        return (_nonces[owner]);
    }

    function _getOwner() private view returns (address) {
        return _owner;
    }
}
