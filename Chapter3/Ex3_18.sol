// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Ex3_18 {

    uint public pub = 1;
    uint private pri = 2;
    uint internal inter = 3;
    //uint external ext = 4;
    function funPub() public view returns(uint, uint, uint){
        return (pub, pri, inter);
    }

    function funPri() private view returns(uint, uint, uint){
        return (pub, pri, inter);
    }

    function funInter() internal view returns(uint, uint, uint){
        return (pub, pri, inter);
    }

    function funExt() external view returns(uint, uint, uint){
        return (pub, pri, inter);
    }
}
