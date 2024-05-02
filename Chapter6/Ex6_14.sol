// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// 다중 상속시 함수 겹치면 오류
/*contract ArtStudent{
    uint public Times = 7;
    function time() public pure returns(uint){
        return 3;
    }
}

contract PartTimer{
    function time() public pure returns(uint){
        return 13;
    }
}

contract Alice is ArtStudent, PartTimer{
    uint public Times = 2;
}*/