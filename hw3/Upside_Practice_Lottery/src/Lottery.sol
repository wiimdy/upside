// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";

contract Lottery {
    /// @notice 사람들이 로또를 살 때 찍는 숫자와 금액
    struct lotte {
        uint num;
        uint amount;
    }
    // 로또의 상태
    enum Phase {
        BUY,
        DRAW,
        CLAIM
    }

    mapping(address => lotte) public lotte_list; // 주소마다 로또를 사 그 정보를 매핑한다.

    Phase private _status; // 로또의 상태
    uint16 private lotte_win_num; // 로또 추첨 번호
    uint256 private winner; // 로또 당첨 사람 수
    uint256 private lotte_time; // lottery 시작 시간
    uint256 private total_awards; // 총 상금
    address[] private participants; // 참가한 사람의 주소

    constructor() {
        lotte_time = block.timestamp;
        _status = Phase.BUY;
    }

    /// @notice 로또를 만들었을 때 필요한 인자 세팅
    function setting() private {
        lotte_time = block.timestamp;
        _status = Phase.BUY;
        winner = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            address participant_ = participants[i];
            delete lotte_list[participant_];
        }
        delete participants;
    }

    /// @notice 사용자가 돈을 보내서 원하는 숫자의 로또를 산다. 각자 하나만 살수 있고 24시간 후에 draw
    /// @param num_ 로또 건 숫자
    function buy(uint num_) public payable {
        if (_status == Phase.CLAIM) setting();
        require(block.timestamp < lotte_time + 24 hours, "Not enough time"); // 시간이 지나기 전에 사야한다
        require(lotte_list[msg.sender].amount == 0, "Only buy one"); // 두번 로또는 안된다
        require(msg.value == 0.1 ether, "Only buy 0.1 ether"); // 0.1 ether로만 로또를 살 수 있다.

        lotte_list[msg.sender].num = num_;
        lotte_list[msg.sender].amount = msg.value;
        participants.push(msg.sender);
        total_awards += msg.value;
    }

    /// @dev 로또 시작 후 24시간이 지나야 추첨 가능하다. 상태가 buy여야지 draw로 바뀐다. 당첨자 수를 계산하고 상태를 claim으로 바꾼다.
    function draw() public {
        address _participant;
        require(lotte_time + 24 hours <= block.timestamp, "Not enough time"); // 시간이 지나기 전에 사야한다
        if (_status == Phase.BUY) _status = Phase.DRAW;
        require(_status == Phase.DRAW, "Only Draw Phase");

        lotte_win_num = winningNumber(); // 결과 추첨
        for (uint i = 0; i < participants.length; i++) {
            _participant = participants[i];
            if (lotte_list[_participant].num == lotte_win_num) winner += 1; // 당첨자 수 계산
        }
        _status = Phase.CLAIM; // 상태 변경
    }

    /// @notice 상태가 claim일 경우 로또 번호를 맞춘 사람에게 총 상금 / 당첨자 를 지급한다. 당첨자가 없을 경우 다음 로또로 이월한다.
    function claim() public payable {
        uint _amount;
        require(lotte_time + 24 hours <= block.timestamp, "Not enough time"); // 시간이 지나기 전에 사야한다
        require(_status == Phase.CLAIM, "Must Claim");

        if (lotte_list[msg.sender].num == lotte_win_num) {
            _amount = total_awards / winner;
        }

        if (_amount != 0) {
            (bool check, ) = payable(msg.sender).call{value: _amount}("");
        }
    }

    /// @notice 로또 당첨 번호를 만드는 함수
    /// @dev 완벽한 난수 생성은 사실 uint16이어서 안전하지 않다고 생각한다.
    /// @return 당첨 번호는 uint16으로 고정되어 있다. (getNextWinningNumber)
    function winningNumber() public view returns (uint16) {
        uint256 rando = uint256(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp))
        );
        return uint16(rando & 0xffff);
    }

    receive() external payable {}
}
