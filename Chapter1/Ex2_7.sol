// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

// 전위 감소와 후위 감소
contract Ex2_7{

    uint a = 5;

    function justA() public view returns(uint){
        return a;
    }

    function prePlus() public returns(uint){
        return --a; // a = a - 1
    }

    function postPlus() public returns(uint){
        return a--; // a = a - 1
    }
}