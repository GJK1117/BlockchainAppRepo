// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ex4_2{

    function fun1(uint a) public pure returns(uint){
        if(a>=10){
            a = 9;
        }
        else{
            a = 10;
        }
        return a;
    }
}