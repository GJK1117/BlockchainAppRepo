// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract Ex7_2 {

    function runRevert(uint _num) public pure returns(uint){
        if(_num<=3){
            //revert => 오류 발생 시킴
            //revert만 명시할 경우 오류가 바로 발생되므로 조건문과 같이 명시
            revert("Revert error: should input more than 3");
        }
        return _num;
    }

    function runRequire(uint _num) public pure returns(uint){
        //require => if문 + revert
        require(_num>3, "Require error: should input more than 3");
        return _num;
    }
}