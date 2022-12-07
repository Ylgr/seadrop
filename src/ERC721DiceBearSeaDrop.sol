// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721SeaDrop.sol";

contract ERC721DiceBearSeaDrop is ERC721SeaDrop {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://raw.githubusercontent.com/Ylgr/seadrop/dicebear_uri/uri/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
}
