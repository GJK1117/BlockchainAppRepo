// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

// 전위 증가와 후위 증가
contract Ex2_6{
    // storage state
    uint a = 5;

    // view : storage state를 변경하지 않고 읽기만 하는 경우 사용 
    function justA() public view returns(uint){
        return a;
    }

    function prePlus() public returns(uint){
        return ++a; // a = a + 1
    }

    function postPlus() public returns(uint){
        return a++; // a = a + 1
    }
}