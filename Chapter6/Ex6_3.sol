// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract Ex6_3{
    //uint[] public immutable arr;
    //uint public constant num1;
    uint public immutable num2;

    constructor(uint _num){
        num2 = _num;
    }
    /*
    function change() public pure returns(uint){
        num2 = 10;
    }
    */
}