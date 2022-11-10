// This program is free software: you can redistribute it and/or modify

pragma solidity 0.5.12;

contract BColor {
    function getColor()
        external view
        returns (bytes32);
}

contract BBronze is BColor {
    function getColor()
        external view
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}
