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

contract InterfaceERC20Token

{
    function balanceOf (address tokenOwner) public constant returns (uint balance);
    function mint (address _to, uint _value) public returns (bool success);
    function burn (address _to, uint _value) public returns (bool success);
}

contract InterfaceERC721Token

{
    function ownerOf (uint256 _tokenId) public constant returns (address); // *ERC /721 +
    function totalSupply () public constant returns (uint256);
    function getAttributeLimit (uint8 _type, uint8 _index) public constant returns (uint256);
    function getTokenAttribute (uint256 _tokenId, uint8 _type, uint8 _index) public constant returns (uint256);
    function getTokenCollectionElement (uint256 _tokenId, uint8 _index, uint256 _element) public constant returns (bool);
    function changeTokenAttribute (uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value) public;
    function transfer (address _to, uint256 _tokenId) public;  // *ERC /721(beta) +
    function transferFrom (address _from, address _to, uint256 _tokenId) public; // *ERC /721 +
    function initialTransfer (address _to, uint256 _tokenId) public;
}

contract Control

{
    
    mapping (address => uint8) public agents;
    
    modifier onlyADM ()
    {
        require (agents[msg.sender] == 1);
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

contract Config is Control

{
    
    address public addressERC20Token; 
    InterfaceERC20Token internal ERC20Token;
    
    address public addressERC721Token; 
    InterfaceERC721Token internal ERC721Token;
   
    modifier onlyOwnerERC721Token (uint256 _tokenId)
    {
        require (msg.sender == ERC721Token.ownerOf (_tokenId)); 
        _;
    }
    
    event ChangeERCTokensSettings (address indexed _agent, address _addressERC20Token, address _addressERC721Token);
    
    function changeERCTokensSettings (address _addressERC20Token, address _addressERC721Token) public onlyRun () onlyADM ()
    {
        addressERC20Token = _addressERC20Token;
        ERC20Token = InterfaceERC20Token (_addressERC20Token);
        
        addressERC721Token = _addressERC721Token;
        ERC721Token = InterfaceERC721Token (_addressERC721Token);
    
        ChangeERCTokensSettings (msg.sender, _addressERC20Token, _addressERC721Token);
    }
    
    uint256 public priceInitialBuyERC721TokenInERC20Token;
    
    uint256 public minPriceBuyERC721TokenInGwei;
    uint256 public minPriceRentERC721TokenInGwei24H;
    
    uint256 public minRentDays;
    uint256 public maxRentDays;
    
    uint256 public commissionBuy;
    uint256 public commissionRent;
    
    event ChangeSaleSettings (address indexed _agent, uint256 _priceInitialBuyERC721TokenInERC20Token, uint256 _minPriceBuyERC721TokenInGwei, uint256 _minPriceRentERC721TokenInGwei24H, uint256 _commissionBuy, uint256 _commissionRent);
    
    function changeSaleSettings (uint256 _priceInitialBuyERC721TokenInERC20Token, uint256 _minPriceBuyERC721TokenInGwei, uint256 _minPriceRentERC721TokenInGwei24H, uint256 _commissionBuy, uint256 _commissionRent) public onlyRun () onlyADM ()
    {
        priceInitialBuyERC721TokenInERC20Token = _priceInitialBuyERC721TokenInERC20Token;
        minPriceBuyERC721TokenInGwei = _minPriceBuyERC721TokenInGwei;
        minPriceRentERC721TokenInGwei24H = _minPriceRentERC721TokenInGwei24H;
        
        require (_commissionBuy <= 50 && _commissionRent <= 50);
        
        commissionBuy = _commissionBuy;
        commissionRent = _commissionRent;
        
        ChangeSaleSettings (msg.sender, _priceInitialBuyERC721TokenInERC20Token, _minPriceBuyERC721TokenInGwei, _minPriceRentERC721TokenInGwei24H, _commissionBuy, _commissionRent);
    }
    
}

contract Lottery is Config

{
    function random (uint256 _min, uint256 _max) public constant returns (uint256)
    {
        return uint256 (sha3 (block.blockhash (block.number - 1))) % (_min + _max) - _min;
    }
    
    event Upgrate (address indexed _called, uint256 _tokenId, uint256 _tokenERC20Count, uint8 _type, uint8 _index);
    
    function upgradeLottery (uint256 _tokenId, uint256 _tokenERC20Count, uint8 _type, uint8 _index) public onlyRun () onlyOwnerERC721Token (_tokenId)
    {
        require (_tokenERC20Count != 0 && _tokenERC20Count <= 10);
        require (_tokenERC20Count <= ERC20Token.balanceOf (msg.sender));
        require (_type == 3 || _type == 4);
        require (_index != 0 && _index <= 5);
        
        uint256 _chance = _tokenERC20Count * 5;
        
        uint256 _limit = ERC721Token.getAttributeLimit (_type, _index);
        require (_limit != 0);
        
        uint256 _presentValue = ERC721Token.getTokenAttribute (_tokenId, _type, _index);
        
        if (random (1, 100) <= _chance)
        {
            if (_type == 3)
            {
                require (_limit > 1);
                
                uint256 _value = random (1,  _limit);
                
                if (_value != _presentValue)
                {
                    ERC721Token.changeTokenAttribute (_tokenId, 3, _index, _value);
                }
                
                if ((_value == _presentValue) && (_value + 1 < _limit))
                {
                    ERC721Token.changeTokenAttribute (_tokenId, 3, _index, _value + 1);
                }
                
                if ((_value == _presentValue) && (_value - 1 != 0))
                {
                    ERC721Token.changeTokenAttribute (_tokenId, 3, _index, _value - 1);
                }
                
            }
            if (_type == 4)
            {
                require (_presentValue <  _limit);
                ERC721Token.changeTokenAttribute (_tokenId, 4, _index, 1);
            }
        
            ERC20Token.burn (msg.sender, _tokenERC20Count);
            Upgrate (msg.sender, _tokenId, _tokenERC20Count, _type, _index);
        }
        
    }
    
    function _rentLottery (uint256 _tokenId, uint256 _amountOfDays, bool _beneficiaryDetected, address _beneficiary) internal
    {
        uint256 _chance;
        uint256 _count;
        
        if (_amountOfDays >= 10)
        {
            _chance = 50;
        }
        else
        {
            _chance = _amountOfDays * 5;
        }
        
        if (random (1, 100) <= _chance)
        {
            _count = random (1, ERC721Token.getTokenAttribute (_tokenId, 4, 1) + 5);
            ERC20Token.mint (msg.sender, _count);
        }
        
        if (_beneficiaryDetected)
        {
            if (random (1, 100) <= 10)
            {
                _count = random (1, ERC721Token.getTokenAttribute (_tokenId, 4, 2) + 5);
                ERC20Token.mint (_beneficiary, _count);
            }
        }
    }
}

contract Market is Lottery //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{
    
    mapping (address => mapping (uint256 => address)) private ERC721TokenBeneficiary;
    mapping (address => mapping (address => uint256[])) private beneficiaryERC721Tokens;
    mapping (address => mapping (uint256 => uint256)) private beneficiaryERC721TokensIndex;
    
    function initialBuyERC721Token (uint256 _tokenId) public onlyRun ()
    {
        require (ERC20Token.balanceOf (msg.sender) >= priceInitialBuyERC721TokenInERC20Token);
        require (ERC20Token.burn (msg.sender, priceInitialBuyERC721TokenInERC20Token));
        ERC721Token.initialTransfer (msg.sender, _tokenId);
    }
    
    modifier onlyBeneficiaryERC721Token (uint256 _tokenId)
    {
        require (msg.sender == ERC721TokenBeneficiary[addressERC721Token][_tokenId]); 
        _;
    }
    
    function balanceERC721TokenOf (address _owner)  public constant returns (uint256)
    {
        return beneficiaryERC721Tokens[addressERC721Token][_owner].length;
    }
    
    function beneficiaryOf (uint256 _tokenId) public constant returns (address) // *ERC /721 +
    {
        return ERC721TokenBeneficiary[addressERC721Token][_tokenId];
    }
    
    function ERC721TokensOf (address _owner) public constant returns (uint256[]) // *ERC /721(beta) +
    {
        return beneficiaryERC721Tokens[addressERC721Token][_owner];
    }
    
    function addToMarketERC721Token (uint256 _tokenId) public onlyRun () onlyOwnerERC721Token (_tokenId)
    {
        ERC721Token.transferFrom (msg.sender, this, _tokenId);
        
        ERC721TokenBeneficiary[addressERC721Token][_tokenId] = msg.sender;
        beneficiaryERC721Tokens[addressERC721Token][msg.sender].push (_tokenId);
        beneficiaryERC721TokensIndex[addressERC721Token][_tokenId] = beneficiaryERC721Tokens[addressERC721Token][msg.sender].length;
    }
    
    function removeFromMarketERC721Token (uint256 _tokenId) public onlyRun () onlyBeneficiaryERC721Token (_tokenId)
    {
        ERC721Token.transfer (msg.sender, _tokenId);
     
        uint256 tokenIndex = beneficiaryERC721TokensIndex[addressERC721Token][_tokenId];
        uint256 lastTokenIndex = balanceERC721TokenOf (msg.sender) - 1;
        uint256 lastToken = beneficiaryERC721Tokens[addressERC721Token][msg.sender][lastTokenIndex];

        ERC721TokenBeneficiary[addressERC721Token][_tokenId] = address (0);
        beneficiaryERC721Tokens[addressERC721Token][msg.sender][tokenIndex] = lastToken;
        beneficiaryERC721Tokens[addressERC721Token][msg.sender][lastTokenIndex] = 0;
        
        beneficiaryERC721Tokens[addressERC721Token][msg.sender].length--;
        beneficiaryERC721TokensIndex[addressERC721Token][_tokenId] = 0;
        beneficiaryERC721TokensIndex[addressERC721Token][lastToken] = tokenIndex;
        
    }
    
    mapping (address => mapping (uint256 => uint256)) private costBuyERC721TokenInGwei;
    
    mapping (address => mapping (uint256 => uint256)) private costRentERC721TokenInGwei24H;
    mapping (address => mapping (uint256 => uint256)) private rangeRendDateERC721Token;
    mapping (address => mapping (uint256 => address)) private ERC721TokenRenter;
    
    function buyERC721Token (uint256 _tokenId) public payable onlyRun ()
    {
        require (beneficiaryOf (_tokenId) != address (0));
        require (beneficiaryOf (_tokenId) !=  msg.sender);
        require (costBuyERC721TokenInGwei[addressERC721Token][_tokenId] > 0);
        require (rangeRendDateERC721Token[addressERC721Token][_tokenId] < block.timestamp);
        uint256 _cost;
        uint256 cost;
        _cost = costBuyERC721TokenInGwei[addressERC721Token][_tokenId];
        cost = _cost * 1000000000; //calculation of gwei in wei
        require (msg.value >= cost);
        address _beneficiary = beneficiaryOf (_tokenId);
        
        msg.sender.transfer (msg.value - cost);
        _beneficiary.transfer (cost - (cost / 100 * commissionBuy));
        
        uint256 tokenIndex = beneficiaryERC721TokensIndex[addressERC721Token][_tokenId];
        uint256 lastTokenIndex = balanceERC721TokenOf (_beneficiary) - 1;
        uint256 lastToken = beneficiaryERC721Tokens[addressERC721Token][_beneficiary][lastTokenIndex];
        
        beneficiaryERC721Tokens[addressERC721Token][_beneficiary][tokenIndex] = lastToken;
        beneficiaryERC721Tokens[addressERC721Token][_beneficiary][lastTokenIndex] = 0;
        beneficiaryERC721Tokens[addressERC721Token][_beneficiary].length--;
        beneficiaryERC721TokensIndex[addressERC721Token][lastToken] = tokenIndex;
        ERC721TokenBeneficiary[addressERC721Token][_tokenId] = msg.sender;
        beneficiaryERC721Tokens[addressERC721Token][msg.sender].push (_tokenId);
        beneficiaryERC721TokensIndex[addressERC721Token][_tokenId] = balanceERC721TokenOf (msg.sender);
    }
    
    function _rentInitialERC721Token (uint256 _tokenId, uint256 _amountOfDays) internal
    {
        require (rangeRendDateERC721Token[addressERC721Token][_tokenId] < block.timestamp);
        require (minRentDays <= _amountOfDays && _amountOfDays <= maxRentDays);
        uint256 cost;
        cost = (minPriceRentERC721TokenInGwei24H * 1000000000) * _amountOfDays;
        require (msg.value >= cost);
        msg.sender.transfer (msg.value - cost);
        rangeRendDateERC721Token[addressERC721Token][_tokenId] = block.timestamp + (_amountOfDays * 86400);
        ERC721TokenRenter[addressERC721Token][_tokenId] = msg.sender;
        
        _rentLottery (_tokenId, _amountOfDays, false, address (0));
    }
    
    function _rentERC721Token (uint256 _tokenId, uint256 _amountOfDays) internal
    {
        require (beneficiaryOf (_tokenId) != address (0));
        require (beneficiaryOf (_tokenId) !=  msg.sender);
        require (costRentERC721TokenInGwei24H[addressERC721Token][_tokenId] > 0);
        require (rangeRendDateERC721Token[addressERC721Token][_tokenId] < block.timestamp);
        require (minRentDays <= _amountOfDays && _amountOfDays <= maxRentDays);
        uint256 cost;
        cost = (costRentERC721TokenInGwei24H[addressERC721Token][_tokenId] * 1000000000) * _amountOfDays;
        require (msg.value >= cost);
        address _beneficiary = beneficiaryOf (_tokenId);
        msg.sender.transfer (msg.value - cost);
        _beneficiary.transfer (cost - (cost / 100 * commissionRent));
        
        rangeRendDateERC721Token[addressERC721Token][_tokenId] = block.timestamp + (_amountOfDays * 86400);
        ERC721TokenRenter[addressERC721Token][_tokenId] = msg.sender;
        
        _rentLottery (_tokenId, _amountOfDays, true, beneficiaryOf (_tokenId));
    }
    
    function rentERC721Token (uint256 _tokenId, uint256 _amountOfDays) public payable onlyRun ()
    {
        if (beneficiaryOf (_tokenId) == address (0) && ERC721Token.ownerOf (_tokenId) == address (0) && _tokenId <= ERC721Token.totalSupply())
        {
            _rentInitialERC721Token (_tokenId, _amountOfDays);
        }
        if (beneficiaryOf (_tokenId) != address (0))
        {
            _rentERC721Token (_tokenId, _amountOfDays);
        }
        
    }
    
    function offerERC721Token (uint256 _tokenId, uint256 _costBuyERC721TokenInGwei, uint256 _costRentERC721TokenInGwei24H) public onlyRun () onlyBeneficiaryERC721Token (_tokenId)
    {
        require (_costBuyERC721TokenInGwei >= minPriceBuyERC721TokenInGwei || _costBuyERC721TokenInGwei == 0);
        require (_costRentERC721TokenInGwei24H >= minPriceRentERC721TokenInGwei24H || _costRentERC721TokenInGwei24H == 0);
        costBuyERC721TokenInGwei[addressERC721Token][_tokenId] = _costBuyERC721TokenInGwei;
        costRentERC721TokenInGwei24H[addressERC721Token][_tokenId] = _costRentERC721TokenInGwei24H;  
    }
    
    function paintRentERC721Token (uint256 _tokenId, uint8 _type, uint8 _index, uint256 _value) public onlyRun ()
    {
        require (_type == 1 || _type == 2);
        require (msg.sender == ERC721TokenRenter[addressERC721Token][_tokenId] && block.timestamp < rangeRendDateERC721Token[addressERC721Token][_tokenId]);
        ERC721Token.changeTokenAttribute (_tokenId, _type, _index, _value);
    }
    
}