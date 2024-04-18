// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract Ex6_1{
    event Myfunction(uint result, string name);
    function add(uint _a, uint _b)public {
        uint total = _a + _b;
        emit Myfunction(total, "add");
    }

    function mul(uint _a, uint _b)public {
        uint total = _a * _b;
        emit Myfunction(total, "mul");
    }
}