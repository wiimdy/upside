// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";

contract Lottery {
    function buy(uint num) public payable {
        // msg.value가 있어야함
        // value가 정상적인 값이어야 함 not 0
        // 중복 되어 있으면 어떤일이지? 뭔가 mapping이 필요한듯
        // 로또 구매 가능 시간이있는듯  시간 저장 변수가 필요
        console.log("value", msg.value);
        payable(msg.sender).call{value: msg.value}("");
    }
    function draw() public {} // 결과 추첨  시간이 지난 후 가능 한번 하고 나서 다시 안됨?
    function claim() public {} // 지급도 시간 지난 후 가능
    function winningNumber() public returns (uint16) {}
}
