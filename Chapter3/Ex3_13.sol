// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Ex3_13 {

    uint public a = 3;
    function myFun() public view returns(uint){
        //외부 변수 함수 내부에서 변경 불가
        a = 4;
        return a;
    }
}
