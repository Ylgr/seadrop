// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC721PartnerSeaDrop.sol";

contract ERC721DiceBearPartnerSeaDrop is ERC721PartnerSeaDrop {
    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) ERC721PartnerSeaDrop(
        name,
        symbol,
        administrator,
        allowedSeaDrop
    ) {
        _mint(msg.sender, 1);
    }

}
