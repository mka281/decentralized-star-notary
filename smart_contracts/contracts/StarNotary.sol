pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract StarNotary is ERC721 {
    struct Star { 
        string name; 
        string ra;
        string dec;
        string mag;
        string starStory;
    }

    mapping(uint256 => Star) public tokenIdToStarInfo; 
    mapping(bytes32 => bool) public createdStars;
    mapping(uint256 => uint256) public starsForSale;

    function createStar(string memory _name, string memory _ra, string memory _dec, string memory _mag, string memory _starStory, uint256 _tokenId) public {
        Star memory newStar = Star(_name, _ra, _dec, _mag, _starStory);
        bytes32 newStarHash = keccak256(abi.encodePacked(_ra, _dec, _mag));

        // If start is not created before, save newStar and newStarHash
        if (createdStars[newStarHash] != true) {
            tokenIdToStarInfo[_tokenId] = newStar;
            createdStars[newStarHash] = true;	
        }

        // Mint token and send it to star creator address
        _mint(msg.sender, _tokenId);
    }

    function putStarUpForSale(uint256 _tokenId, uint256 _price) public { 
        // Only star owner can call this function
        require(this.ownerOf(_tokenId) == msg.sender);

        // Set star price
        starsForSale[_tokenId] = _price;
    }

    function buyStar(uint256 _tokenId) public payable { 
        // Verify if the star is for sale
        require(starsForSale[_tokenId] > 0);
        
        // Verify if the amount is enough
        uint256 starCost = starsForSale[_tokenId];
        require(msg.value >= starCost);

        // Transfer token and cost
        address payable starOwner = address(uint160(bytes20(this.ownerOf(_tokenId))));
        _removeTokenFrom(starOwner, _tokenId);
        _addTokenTo(msg.sender, _tokenId);
        starOwner.transfer(starCost);

        // If there is more value than the cost, return it to buyer
        if(msg.value > starCost) { 
            msg.sender.transfer(msg.value - starCost);
        }

        // Take the star off the sale list
        delete(starsForSale[_tokenId]);
    }
}