// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Constants {
    mapping(string chain => address) private layerZeroEndpoints;
    mapping(string chain => uint32) private EIDs;

    constructor() {
        layerZeroEndpoints["arbitrum-sepolia"] = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        layerZeroEndpoints["mainnet-sepolia"] = 0x6EDCE65403992e310A62460808c4b910D972f10f;

        EIDs["arbitrum-sepolia"] = 40231;
        EIDs["mainnet-sepolia"] = 40161;
    }

    function getLayerZeroEndpoint(string memory chain) public view returns (address endpoint) {
        endpoint = layerZeroEndpoints[chain];
        if (endpoint == address(0)) revert LayerZeroEndpointNotFound(chain);
    }

    function getEID(string memory chain) public view returns (uint32 eid) {
        eid = EIDs[chain];
        if (eid == 0) revert EIDNotFound(chain);
    }

    // File constants
    string constant Underscore = "_";
    string constant Dash = "-";
    string constant Slash = "/";

    // Colors for console logs
    string constant BLUE = "\u001b[34m";
    string constant GREEN = "\u001b[32m";
    string constant RED = "\u001b[31m";
    string constant YELLOW = "\u001b[33m";
    string constant MAGENTA = "\u001b[35m";
    string constant CYAN = "\u001b[36m";
    string constant WHITE = "\u001b[37m";
    string constant BLACK = "\u001b[30m";
    string constant RESET = "\u001b[0m";

    error LayerZeroEndpointNotFound(string chain);
    error EIDNotFound(string chain);
}

