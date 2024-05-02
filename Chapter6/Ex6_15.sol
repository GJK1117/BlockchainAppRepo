// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ArtStudent{
    uint private schoolHours;
    constructor(uint _schoolHours){
        schoolHours = _schoolHours;
    }
    function time() public virtual returns(uint){
        return schoolHours;
    }
}

contract PartTimer{
    uint private workingHours;
    constructor(uint _workingHours){
        workingHours = _workingHours;
    }
    function time() public virtual returns(uint){
        return workingHours;
    }
}

contract Alice is ArtStudent(5), PartTimer(6){
    function time() public override(ArtStudent, PartTimer) returns(uint){
        return super.time();
    }
}