// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Ex3_4 {

    uint public a = 3;
    function myFun(uint b, uint c, uint d) public {
        a = b;
        a = c;
        a = d;
    }
}
