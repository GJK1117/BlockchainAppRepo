// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract Student{
    string[] internal courses;

    function showCourse() public virtual returns(string[] memory){
        delete courses;
        courses.push("English");
        courses.push("Music");
        return courses;
    }
}

contract ArtStudent is Student{
    function showCourse() public override returns(string[] memory){
        super.showCourse();
        courses.push("Art");
        return courses;
    }
}