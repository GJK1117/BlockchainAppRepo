// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

// 복합 할당 연산자
contract Ex2_5{
    uint a = 5;
    uint b = 5;
    uint c = 5;
    uint d = 5;
    uint e = 5;

    function compoundAssignment() public returns(uint, uint, uint, uint, uint){

        a += 2; // a = a + 2
        b -= 2; // b = b - 2
        c *= 2; // c = c * 2
        d /= 2; // d = d / 2
        e %= 2; // e = e % 2
        return (a, b, c, d, e);
    }
}