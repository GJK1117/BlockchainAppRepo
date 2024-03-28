// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Ex3_11 {

    uint public a = 3;
    function myFun() public pure returns(uint){
        //pure 잘못 사용한 경우
        a = 4;
        return a;
    }
}
