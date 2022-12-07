import "./ERC721SeaDrop.sol";

contract ERC721DiceBearSeaDrop is ERC721SeaDrop {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    string public baseURI = "https://raw.githubusercontent.com/Ylgr/seadrop/dicebear_uri/uri/";
    string public baseExtension = ".json";

    function setBaseURI(string memory _value) external onlyOwner {
        baseURI = _value;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
}
