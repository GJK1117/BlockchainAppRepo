// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Ex3_10 {

    function myFun(string calldata str) external pure returns(string memory){
        return str;
    }
}
