// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ex5_5 {

    uint[] public array = [97, 98, 99];

    function getLength() public view returns(uint){
        return array.length;
    }

    //마지막 인덱스 삭제
    function popArray() public{
        array.pop();
    }

    //원하는 인덱스 값 삭제
    function deleteArray(uint _index) public {
        delete array[_index];
    }
}