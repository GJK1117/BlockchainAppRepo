// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

// 대입 연산자
contract Ex2_2{
    string a = "Hello";

    function assignment() public returns(string memory){
        

        a = "Hello Solidity";
        return(a);
    }
}