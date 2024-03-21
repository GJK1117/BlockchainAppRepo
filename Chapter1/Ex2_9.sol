// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

// 비교 연산자
contract Ex2_9{
    bool a = true && true;
    bool b = true && false;
    bool c = false && false;
    bool d = true || true;
    bool e = true || false;
    bool f = false || false;
    bool g = !false;

    function logical() public view returns(bool, bool, bool, bool, bool, bool, bool){
        return(a, b, c, d, e, f, g);
    }
}