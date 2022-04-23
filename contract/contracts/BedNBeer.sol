// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BedNBeer
 * BedNBeer - Base smart contract using ERC-721 Standard
 */
contract BedNBeer is ERC721, ERC721URIStorage, Ownable {
    mapping(string => address) public _creatorsMapping;
    mapping(uint256 => string) public _tokenIdsMapping;
    mapping(uint256 => uint256) public _wenData;
    uint256 hardCap = 0;
    string private baseURI = "ipfs://";
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    event Minted(uint256 indexed tokenId);

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function nftExists(string memory tokenHash) public view returns (bool) {
        address owner = _creatorsMapping[tokenHash];
        return owner != address(0);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /*
        This method will mint the token to sender user
    */
    function mint(string memory _tokenURI, uint256 wen) public payable {
        require(
            !nftExists(_tokenURI),
            "BedNBeer: Trying to mint existent nft"
        );
        require(msg.value > 0, "Must send something");
        uint256 id = mintTo(msg.sender, _tokenURI);
        _wenData[id] = wen;
    }

    /*
        Private method that mints the token
    */
    function mintTo(address _to, string memory _tokenURI)
        private
        returns (uint256)
    {
        if (hardCap > 0) {
            uint256 reached = _tokenIdCounter.current() + 1;
            require(reached <= hardCap, "BedNBeer: Hard cap reached");
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        _creatorsMapping[_tokenURI] = _to;
        _tokenIdsMapping[newTokenId] = _tokenURI;
        emit Minted(newTokenId);
        return newTokenId;
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(_tokenId);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        bool success;
        (success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdraw to vault failed");
    }
}
