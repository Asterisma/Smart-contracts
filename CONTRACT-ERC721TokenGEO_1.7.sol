/*
This Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This Contract is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.
You should have received a copy of the GNU lesser General Public License
<http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.23;

contract Control
{
    
    mapping (address => uint8) public agents;
    
    modifier onlyADM ()
    {
        require (agents[msg.sender] == 1);
        _;
    }
    
    modifier onlyGVR ()
    {
        require (agents[msg.sender] == 2);
        _;
    }
    
    modifier onlySPR ()
    {
        require (agents[msg.sender] == 3);
        _;   
    }
    
    event ChangePermission (address indexed _called, address indexed _agent, uint8 _value);
    
    function changePermission (address _agent, uint8 _value) public onlyADM ()
    {
        require (msg.sender != _agent);
        agents[_agent] = _value;
        ChangePermission (msg.sender, _agent, _value);
    }
    
    bool public status;
    
    event ChangeStatus (address indexed _called, bool _value);
    
    function changeStatus (bool _value) public onlyADM ()
    {
        status = _value;
        ChangeStatus (msg.sender, _value);
    }
    
    modifier onlyRun ()
    {
        require (status);
        _;
    }
    
    event Donate (address indexed _from, uint _value);
    
    function () payable //Thank you very much
    {
        Donate (msg.sender, msg.value);
    }
    
    function withdrawalETH (address _to) public onlyADM ()
    {
        _to.transfer (this.balance);
    }
    
    function destroy (address _to) public onlySPR ()
    {
        selfdestruct (_to);
    }
    
    function Control ()
    {
        agents[msg.sender] = 1;
        status = true;
    }
    
}

interface ERC721TokenReceiver
{
	function onERC721Received (address _from, uint256 _tokenId, bytes _data) external returns (bytes4);
}

contract OwnershipToken is Control

{
    
    event Transfer (address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval (address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll (address indexed _owner, address indexed _operator, bool _approved);
    
    mapping (uint256 => address) private tokenOwner;
    mapping (address => uint256[]) private ownedTokens;
    mapping (uint256 => uint256) private ownedTokensIndex;
    mapping (uint256 => address) private tokenApprovals;
    mapping (address => mapping (address => bool)) private operatorApprovals;
    
    uint256 private totalTokens;
    
    modifier onlyReal (uint256 _tokenId)
    {
        require (_tokenId > 0 && _tokenId <= totalTokens); 
        _;
    }
    
    modifier onlyOwner (uint256 _tokenId)
    {
        require (msg.sender == tokenOwner[_tokenId]); 
        _;
    }
    
    function balanceOf (address _owner) public constant returns (uint256) // *ERC /721/20 +
    {
        return ownedTokens[_owner].length;
    }
    
    function ownerOf (uint256 _tokenId) public constant returns (address) // *ERC /721 +
    {
        return tokenOwner[_tokenId];
    }
    
    function tokensOf (address _owner) public constant returns (uint256[]) // *ERC /721(beta) +
    {
        return ownedTokens[_owner];
    }
    
    function getApproved (uint256 _tokenId) public constant returns (address) // *ERC /721 +
    {
        return tokenApprovals[_tokenId];  
    }

    function isApprovedForAll (address _owner, address _operator) public constant returns (bool) // *ERC /721 +
    {
        return operatorApprovals[_owner][_operator];    
    }
    
    function supportsInterface (bytes4 _interfaceID) public constant returns (bool) // *ERC /721 +
    {
        return
        _interfaceID == this.supportsInterface.selector || // ERC165
        _interfaceID == 0x5b5e139f || // ERC721Metadata
        _interfaceID == 0x6466353c || // ERC-721 on 3/7/2018
        _interfaceID == 0x780e9d63; // ERC721Enumerable
    }
    
    function initialTransfer (address _to, uint256 _tokenId) public onlyRun () onlyReal (_tokenId) onlyGVR ()
    {
        require (tokenOwner[_tokenId] == address (0));
        require (_to != address (0));
        tokenOwner[_tokenId] = _to;
        ownedTokens[_to].push (_tokenId);
        ownedTokensIndex[_tokenId] = ownedTokens[_to].length;
        Transfer (address (0), _to, _tokenId);
    }
    
    function _transfer (address _to, uint256 _tokenId) private onlyRun () onlyReal (_tokenId)
    {
        require (_to != ownerOf (_tokenId));
        require (_to != address (0));
        tokenApprovals[_tokenId] = 0;
        Approval (msg.sender, 0, _tokenId);
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf (msg.sender) - 1;
        uint256 lastToken = ownedTokens[msg.sender][lastTokenIndex];
        ownedTokens[msg.sender][tokenIndex] = lastToken;
        ownedTokens[msg.sender][lastTokenIndex] = 0;
        ownedTokens[msg.sender].length--;
        ownedTokensIndex[lastToken] = tokenIndex;
        tokenOwner[_tokenId] = _to;
        ownedTokens[_to].push (_tokenId);
        ownedTokensIndex[_tokenId] = balanceOf (_to);
        Transfer (msg.sender, _to, _tokenId);
    }
    
    function transfer (address _to, uint256 _tokenId) public onlyOwner (_tokenId) // *ERC /721(beta) +
    {
        _transfer (_to, _tokenId);
    }
    
    function approve (address _to, uint256 _tokenId) public onlyRun () onlyOwner (_tokenId) // *ERC /721 +
    {
        require (_to != ownerOf (_tokenId));
        require (_to != address (0));
        tokenApprovals[_tokenId] = _to;
        Approval (msg.sender, _to, _tokenId);
    }
    
    function setApprovalForAll (address _operator, bool _approved) public onlyRun () // *ERC /721 +
    {
        if (_approved)
        {
            require (_operator != msg.sender);
            require (_operator != address (0));
            operatorApprovals[msg.sender][_operator] = true;
            ApprovalForAll (msg.sender, _operator, true);
        }
        else
        {
            require (_operator != msg.sender);
            operatorApprovals[msg.sender][_operator] = false;
            ApprovalForAll (msg.sender, _operator, false);
        }  
    }
    
    function transferFrom (address _from, address _to, uint256 _tokenId) public // *ERC /721 +
    {
        require (ownerOf (_tokenId) == msg.sender || getApproved (_tokenId) == msg.sender || isApprovedForAll (ownerOf (_tokenId), msg.sender));
        require (ownerOf (_tokenId) == _from);
        _transfer (_to, _tokenId);
    }
    
    function _isContract (address _agent) private constant returns (bool)
    {
        uint size;
        assembly { size := extcodesize (_agent) }
        return size > 0;
    }
    
    function safeTransferFrom (address _from, address _to, uint256 _tokenId, bytes _data) public // *ERC /721 +
    {
        transferFrom (_from, _to, _tokenId);
        if (_isContract (_to))
        {
            bytes4 tokenReceiverResponse = ERC721TokenReceiver (_to).onERC721Received.gas (50000) (_from, _tokenId, _data);
            require (tokenReceiverResponse == bytes4 (keccak256 ("onERC721Received(address,uint256,bytes)")));
        }
    }
    
    function safeTransferFrom (address _from, address _to, uint256 _tokenId) public // *ERC /721 +
    {
        safeTransferFrom (_from, _to, _tokenId, "");
    }
    
    function totalSupply () public constant returns (uint256) // *ERC /721(metadata/optional)/20 +
    {
        return totalTokens;
    }
    
    function tokenByIndex (uint256 _index) public constant returns (uint256) // *ERC /721(metadata/optional) +
    {
        require (_index <= totalSupply ());
        return _index; 
    }
    
    function tokenOfOwnerByIndex (address _owner, uint256 _index) public constant returns (uint256) // *ERC /721(metadata/optional) +
    {
        require(_index < balanceOf (_owner));
        return ownedTokens[_owner][_index];
    }
    
    function OwnershipToken ()
    {
        totalTokens = 0;
    }
    
}

contract BaseToken is OwnershipToken

{

    //ATTRIBUTES//
    /*
    1 (0) - Owner / one of the range
    2 (1) - Owner / one of the collection
    3 (2) - GVR / one of range
    4 (3) - GVR / one progressive out of range
    */
    //////////////
    
    uint256[5][4] private attributeLimit;
    
    struct token
    {
        mapping (uint256 => bool)[5] collections;
        uint256[5][4] attribute;
    }
    
    mapping (uint256 => token) private tokens;
    
    function getAttributeLimit (uint8 _type, uint8 _index) public constant returns (uint256)
    {
        return attributeLimit[_type - 1][_index - 1];
    }
    
    event ChangeAttributeLimit (address indexed _called, uint8 _type, uint8 _index, uint256 _value);
    
    function changeAttributeLimit (uint8 _type, uint8 _index, uint256 _value) public onlyRun () onlyADM ()
    {
        require ((_type > 0 && _type <= 4) && (_index > 0 && _index <= 5));
        attributeLimit[_type - 1][_index - 1] = _value;
        ChangeAttributeLimit (msg.sender, _type, _index, _value);
    }
    
    function getTokenAttribute (uint256 _tokenId, uint8 _type, uint8 _index) public constant returns (uint256)
    {
        return tokens[_tokenId].attribute[_type - 1][_index - 1];
    }
    
    function getTokenCollectionElement (uint256 _tokenId, uint8 _index, uint256 _element) public constant returns (bool)
    {
        return tokens[_tokenId].collections[_index][_element];
    }
    
    event AddTokenCollectionElement (address indexed _called, uint256 _tokenId, uint8 _type, uint8 _index, bool _value);
    
    function addTokenCollectionElement (uint256 _tokenId, uint8 _index, uint256 _element) public onlyRun () onlyReal (_tokenId) onlyGVR ()
    {
        require ((_index > 0 && _index <= 5) && (_value <= attributeLimit[1].[_index - 1]));
        tokens[_tokenId].collections[_index - 1][_element] = true;
    }
    
    event ChangeTokenAttribute (address indexed _called, uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value);
    
    function changeTokenAttribute (uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value) public onlyRun () onlyReal (_tokenId)
    {
        require (_type > 0 && _type <= 4);
        require (_index > 0 && _index <= 5);
        require (_value > 0);
        require (attributeLimit[_type -1].[_index - 1] != 0);
        
        if (_type <= 2)
        {
            _changeTokenAttributeOwner (_tokenId, _type, _index, _value);
        }
        else
        {
            _changeTokenAttributeGVR (_tokenId, _type, _index, _value);
        }
        
        ChangeTokenAttribute (msg.sender, _tokenId, _type, _index, _value);
    }
    
    function _changeTokenAttributeOwner (uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value) private onlyOwner (_tokenId)
    {
        if (_type == 1)
        {
            require ((attributeLimit[0].[_index - 1] == 1) || (_value <= attributeLimit[0].[_index - 1]));
            tokens[_tokenId].attribute[0].[_index - 1] = _value;
        }
        else
        {
            require (tokens[_tokenId].collections[_index - 1][_value]);
            tokens[_tokenId].attribute[1].[_index - 1] = _value;
        }
    }
    
    function _changeTokenAttributeGVR (uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value) private onlyGVR ()
    {
        if (_type == 3)
        {
            require (_value <= attributeLimit[2].[_index - 1]);
            tokens[_tokenId].attribute[2].[_index - 1] = _value;
        }
        else
        {
            uint256 _upValue = tokens[_tokenId].attribute[3].[_index - 1] + _value;
            require ((_upValue <= attributeLimit[3].[_index - 1]) && (_upValue > tokens[_tokenId].attribute[3].[_index - 1]));
            tokens[_tokenId].attribute[3].[_index - 1] = _upValue;
        }
    }
    
}

contract Metadata is BaseToken

{
    uint8 public constant decimals = 0; // *ERC /721(optional)/20 +
    string public URI;
    string public tokenURI;
    string public constant name = "Section of Celestial GEO-space";
    string public constant symbol = "GEO";
    
    event ChanegeURI (address indexed _called, string _uri, string _tokenURI);
    
    function changeURI (string _uri, string _tokenURI) public onlyADM ()
    {
        URI = _uri;
        tokenURI = _tokenURI;
        ChanegeURI (msg.sender, _uri, _tokenURI);
    }
    
}

contract MarketInterface

{
    function transferERC721TokenToMarket (address _from, uint256 _tokenId) public;
}

contract Core is Metadata

{
    address public marketAdress;

    MarketInterface internal market;
    
    event ChangeMarketAddress (address indexed _called, address indexed _market);
    
    function changeMarketAddress (address _marketAdress) public onlyADM ()
    {
        marketAdress = _marketAdress;
        market = MarketInterface (_marketAdress);
        ChangeMarketAddress (msg.sender, _marketAdress);
    }
    
    event TransferToMarket (address indexed _from, address indexed _market, uint256 _tokenId);
    
    function transferToMarket (uint256 _tokenId) public
    {
        transfer (marketAdress, _tokenId);
        market.transferERC721TokenToMarket (msg.sender, _tokenId);
        TransferToMarket (msg.sender, marketAdress, _tokenId);
    }
    
}