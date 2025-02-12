// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";

contract Quiz {
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    mapping(address => uint256)[] public bets;
    uint public vault_balance; // 배팅으로 진 돈을 보관...?

    mapping(uint => Quiz_item) public Quiz_list; //id 와 quiz_item을 연결하는 맵핑 생성
    address owner; // quiz 추가를 owner 만 가능  acl을 위해 추가
    uint public list_count;

    constructor() {
        owner = msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        // 여기서 뭔가 저장되어야 할 느낌
        require(owner == msg.sender, "Only Owner!");
        Quiz_list[q.id] = Quiz_item({
            id: q.id,
            question: q.question,
            answer: q.answer,
            min_bet: q.min_bet,
            max_bet: q.max_bet
        });
        list_count++;
    }

    // answer를 물어볼때 아무다 다 가능한가..?
    function getAnswer(uint quizId) public view returns (string memory) {
        require(owner == msg.sender, "Only Owner!");

        return (Quiz_list[quizId].answer);
    }

    // quiz를 반환할때는 답을 지우고 보내야 한다.
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        //quiz_item arr가 있어야 한다.
        Quiz.Quiz_item memory q = Quiz_list[quizId];
        q.answer = "";
        return (q);
    }

    function getQuizNum() public view returns (uint) {
        // 사실 quiz.id내보내면 되는거 아닌가
        return (list_count);
    }

    // 돈을 걸었으니 빼주고 또 검증을 해야 한다.
    function betToPlay(uint quizId) public payable {
        // callfh msg.value 보내고 quiz id에 건다...?
        require(
            (Quiz_list[quizId].min_bet <= msg.value) &&
                (msg.value <= Quiz_list[quizId].max_bet),
            "Inavalid msg.value"
        );
        if (bets.length < quizId) {
            bets.push(); // 빈 mapping 추가
        }
        bets[quizId - 1][msg.sender] += msg.value;
    }

    // memory storage 차이에 의해 keeccak 비교 진행
    // 만약 맞추면 보상 진행?? claim과 따로??
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        if (
            keccak256(abi.encodePacked(Quiz_list[quizId].answer)) ==
            keccak256(abi.encodePacked(ans))
        ) return true;
        vault_balance += bets[quizId - 1][msg.sender];
        bets[quizId - 1][msg.sender] = 0; //틀리면 건돈 다 잃는다
        return false;
    }
    // 돈을 땃으니 건 돈의 두배를 준다.
    function claim(uint quizId) public {
        uint awards = bets[quizId - 1][msg.sender] * 2;
        payable(msg.sender).call{value: awards}("");
        bets[quizId - 1][msg.sender] = 0;
    }

    receive() external payable {} // 돈을 받기 위해 생성
}
