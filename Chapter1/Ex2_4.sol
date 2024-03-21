// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

// 산술 연산자
contract Ex2_4{
    uint a = 5+2;
    uint b = 5-2;
    uint c = 5*2;
    uint d = 5/5;
    uint e = 5%2;
    uint f = 5**2;

    function assignment() public view returns (uint, uint, uint, uint, uint, uint){
        return (a, b, c, d, e, f);
    }
}