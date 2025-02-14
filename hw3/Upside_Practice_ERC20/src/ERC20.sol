// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "../lib/forge-std/src/Test.sol";
contract ERC20 {
    mapping(address => uint256) private _nonces; // 각 계정의 최근 사용한 nonce 값 저장
    mapping(address => uint256) private _balances; // 각 계정에 잔고 매핑
    mapping(address => mapping(address => uint256)) private _allowances; // 이중 매핑으로 allowance

    bool private _pause; // contract가 stop 상태인지 나타내는 변수
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private _owner;

    constructor(string memory name_, string memory symbols_) {
        _name = name_;
        _symbol = symbols_;
        _owner = msg.sender;
        _totalSupply = 200 ether; // 초기 발행량 200 ether로 설정
        _balances[_getOwner()] = _totalSupply;
        _pause = false;
    }

    /// @notice contract 소유자만 함수 실행 하게 만든 modifier
    modifier onlyOwner() {
        require(_getOwner() == msg.sender, "Only Owner");
        _;
    }

    /// @notice _pause 상태가 아닐 때 함수 실행할 수 있게 만든 modifer
    modifier whenNotPaused() {
        require(_pause == false, "Work when Not pause");
        _;
    }

    /// @notice _puase 상태 설정하는 함수
    function pause() public onlyOwner {
        _pause = true;
    }

    /// @notice struct hash를 Eip191, 712에 따라 prefix로 \x19\x01를 넣고 struct를 해시한다.
    /// @param hash 실행 시킬 함수를 인코딩하여 struct hash 값을 해시 함수 통해 내보낸다
    function _toTypedDataHash(bytes32 hash) public pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", hash));
        return (digest);
    }

    /// @notice 기존의 approve, transferfrom의 문제를 해결하기 위해 한번의 transaction으로 진행한다.
    /// @dev 서명 값을 받아 서명의 소유자 주소를 구해 실제 owner와 일치하는지 비교, nonce 값 비교를 진행한다.
    ///      transaction이 완료되면
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

    /// @notice 주소에 맞는 nonce 값 반환
    function nonces(address owner) external view returns (uint256) {
        return (_nonces[owner]);
    }

    function _getOwner() private view returns (address) {
        return _owner;
    }

    function transfer(address to, uint256 amount) public {
        address owner = msg.sender;
        _tranfser(owner, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        address spender = msg.sender;
        uint256 fromAllowance = _allowances[from][spender];
        require(amount <= fromAllowance, "Not encough allowance");
        _allowances[from][spender] -= amount;
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
}
