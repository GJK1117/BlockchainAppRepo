// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract Student{
    string public schoolName = "The University of Solidity";
}

contract ArtStudent is Student{
    function getSchoolName() public view returns(string memory){
        return schoolName;
    }

    function changeSchoolName() public{
        schoolName = "The University of BlockChain";
    }
}