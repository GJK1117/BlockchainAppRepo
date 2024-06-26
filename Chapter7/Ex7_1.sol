// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract Ex7_1 {

    function runAssert(bool _bool) public pure returns(bool){
        //false면 assert 오류 발생, true 면 오류 발생 X
        assert(_bool);
        return _bool;
    }

    function divisionByZero(uint _num1, uint _num2) public pure returns(uint) {
        return _num1/_num2;
    }
}