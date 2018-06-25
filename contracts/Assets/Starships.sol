pragma solidity ^0.4.23;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

}


contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }



  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

}


/// @title A facet of starCore that manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co)
contract AccessControl {

    event ContractUpgrade(address newContract);

    // Address of the 1st dev
    address public primaryAddress;

    // Address of the 2nd dev
    address public secondaryAddress;

    // Address of the 3rd dev
    address public tertiaryAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Access modifier for 1st dev-only functionality
    modifier onlyPrimary() {
        require(msg.sender == primaryAddress);
        _;
    }

    // @dev Access modifier for 2nd dev-only functionality
    modifier onlySecondary() {
        require(msg.sender == secondaryAddress);
        _;
    }

    // @dev Access modifier for 3rd dev-only functionality
    modifier onlyTertiary() {
        require(msg.sender == tertiaryAddress);
        _;
    }

    // @dev Access modifier for devs-only functionality
    modifier onlyDevs() {
        require(
            msg.sender == tertiaryAddress ||
            msg.sender == primaryAddress ||
            msg.sender == secondaryAddress
        );
        _;
    }

    // @dev Assigns a new address to act as the 1st dev. Only available to the current 1st dev.
    // @param _newPrimary The address of the new 1st dev
    function setPrimary(address _newPrimary) external onlyPrimary {
        require(_newPrimary != address(0));

        primaryAddress = _newPrimary;
    }

    // @dev Assigns a new address to act as the 2nd dev. Only available to the current 1st dev.
    // @param _newPrimary The address of the new 2nd dev
    function setSecondary(address _newSecondary) external onlyPrimary {
        require(_newSecondary != address(0));

        secondaryAddress = _newSecondary;
    }

    // @dev Assigns a new address to act as the 3rd dev. Only available to the current 1st dev.
    // @param _newPrimary The address of the new 3rd dev
    function setTertiary(address _newTertiary) external onlyPrimary {
        require(_newTertiary != address(0));

        tertiaryAddress = _newTertiary;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyDevs whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyPrimary whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

/**
 * @title helpers
 * This implementation includes all the functions required in various contracts to execute some logic
 * All the helper functions are here
 */
contract helpers {
  /**
   * @dev function to convert a string into an uint
   * @param _a string to be converted into uint
   * @return uint representing the integer value of the input string
   */
  function parseInt(string _a) internal pure returns (uint) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i=0; i<bresult.length; i++){
      if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
        if (decimals){
          break;
        }
        mint *= 10;
        mint += uint(bresult[i]) - 48;
      } else if (bresult[i] == 46) decimals = true;
    }
    return mint;
  }

  /**
   * @dev function to convert a uint into a string
   * @param i uint to be converted into string
   * @return string form of the input integer
   */
  function uint2str(uint i) internal pure returns (string){
          if (i == 0) return "0";
          uint j = i;
          uint len;
          while (j != 0){
              len++;
              j /= 10;
          }
          bytes memory bstr = new bytes(len);
          uint k = len - 1;
          while (i != 0){
              bstr[k--] = byte(48 + i % 10);
              i /= 10;
          }
          return string(bstr);
      }
}


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721BasicToken, helpers, AccessControl {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Address of developers
  address internal dev;

  // Structs to hold the characteristics of a ship
  struct Ship{

    // Rarity
    uint8 rarity;

    // Speed(level) of ship
    uint8 speed;

    // level of the ship
    uint8 level;

    // Attacking Power
    uint16 attackAbility;

    // Defence/Health
    uint16 defenceElements;

    // Amount of stardust required for the battle
    uint battleStardust;

    // Price of ship
    uint price;

    // Id of the planet associated
    uint parentPlanet;

    // the ship is for sale or not
    bool forSale;

    // Weapons count
    string turrets;
  }


  // starships array
  Ship[] ships;

    // starship id to Owner
  mapping(uint => address) shipToOwner;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   * @param _name name of the token
   * @param _symbol symbol of the token
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
    dev = msg.sender;
  }


  /**
   * @dev function to create a ship
   * @param _rarity uint8 representing the rarity of the ship
   * @param _speed uint8 representing the speed of the ship
   * @param _attack uint16 representing the attacking power of the ship
   * @param _defence uint16 representing the defence capability of the ship
   * @param _stardust uint representing the amount of stardust required by the battleship for a battle
   * @param _owner address of the intended owner of the ship
   */
  function createAShip(uint8 _rarity, uint8 _speed, uint16 _attack, uint16 _defence, uint _planetId, uint _stardust, address _owner) public returns (uint){
    Ship memory ship;
    ship.rarity = _rarity;
    ship.level = 1;
    ship.attackAbility = _attack;
    ship.speed = _speed;
    ship.defenceElements = _defence;
    ship.battleStardust = _stardust;
    ship.turrets = "111100000000000000000000000000";
    ship.price = 0;
    ship.parentPlanet = _planetId;
    ship.forSale = false;
    uint id = ships.push(ship) - 1;
    shipToOwner[id] = _owner;
    _mint(_owner,id);
    return id;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }



  /**
   * @dev Gets the ship's rarity
   * @param _id uint representing the id of the ship
   * @return uint8 representing the rarity of ship
   */
  function rarityOfShip(uint _id) public view returns (uint8) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].rarity;
  }

  /**
   * @dev Gets the planet id associated with the ship
   * @param _id uint representing the id of the ship
   * @return uint representing the id of the planet associated
   */
  function planetOfShip(uint _id) public view returns (uint) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].parentPlanet;
  }

  /**
   * @dev Gets the ship's weapons
   * @param _id uint representing the id of the ship
   * @return uint8 representing the weapons number of ship
   */
  function turretsOfShip(uint _id) public view returns (string) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].turrets;
  }

  /**
   * @dev Gets the ship's weapons
   * @param _id uint representing the id of the ship
   * @return uint8 representing the weapons number of ship
   */
  function speedOfShip(uint _id) public view returns (uint8) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].speed;
  }

  /**
   * @dev Gets the ship's level
   * @param _id uint representing the id of the ship
   * @return uint8 representing the level of ship
   */
  function levelOfShip(uint _id) public view returns (uint8) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].level;
  }

  /**
   * @dev Gets the ship's attacking power
   * @param _id uint representing the id of the ship
   * @return uint16 representing the attacking power of ship
   */
  function attackOfShip(uint _id) public view returns (uint16) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].attackAbility;
  }

  /**
   * @dev Gets the ship's defence/health
   * @param _id uint representing the id of the ship
   * @return uint16 representing the defence/health elements of ship
   */
  function defenceOfShip(uint _id) public view returns (uint16) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].defenceElements;
  }

  /**
   * @dev Gets the amount of stardust required by the ship required for the battle
   * @param _id uint representing the id of the ship
   * @return uint representing the amount of stardust required by the ship required for the battle
   */
  function stardustRequired(uint _id) public view returns (uint) {
    //require(msg.sender == shipToOwner[_id]);
    return ships[_id].battleStardust;
  }

  /**
   * @dev Gets the price of the ship
   * @param _id uint representing the id of the ship
   * @return uint representing the price of the ship
   */
  function priceOfShip(uint _id) public view returns (uint) {
    return ships[_id].price;
  }

  /**
   * @dev Gets whether the ship is gor sale or not
   * @param _id uint representing the id of the ship
   * @return bool representing whether the ship is for sale or not
   */
  function shipForSale(uint _id) public view returns (bool) {
    return ships[_id].forSale;
  }

  /**
   * @dev ship turrets as well as ship level up function
   * @param _shipId Id of the ship to be upgraded
   * @param _turrentId Id of the turret to be upgraded
   */

  bytes temp;
  function shipTurretLevelUp(uint _shipId, uint _turrentId) public  {
    require(msg.sender == shipToOwner[_shipId]);
    Ship memory shipp = ships[_shipId];
    temp = bytes(shipp.turrets);
    bytes1 l = temp[_turrentId];
    bytes memory bytesStringTrimmed = new bytes(1);
    bytesStringTrimmed[0] = l;
    uint a = parseInt(string(bytesStringTrimmed));
    require(a > 0, "You do not have this turret");
    //require(shipToOwner[_shipId].stardust >= cost[shipp.level][shipp.rarity]);
    a++;
    bytes memory n = bytes(uint2str(a));
    temp[_turrentId] = n[0];
    shipp.turrets = string(temp);
    uint min = 5;
    for(uint i=0; i< temp.length; i++){
      bytesStringTrimmed[0] = temp[i];
      a = parseInt(string(bytesStringTrimmed));
      if(a>0 && a<min){
        min = a;
      }
    }
    ships[_shipId] = shipp;
    if(shipp.level < min){
        shipLevelUp(_shipId);
    }
  }

  function shipLevelUp(uint _id) internal {
    //require(msg.sender == idToOwner[_id]);
    Ship memory s = ships[_id];
    s.level++;
    s.speed += 10;
    s.attackAbility += 10;
    s.defenceElements += 10;
    //s.battleStardust
    ships[_id] = s;
  }


  /**
   * @dev function to transfer ownership of the ship
   * @param _to address of the new owner
   * @param _id Id of the ship to be transferred
   */
  function transferShip(address _to, uint _id ) internal {
    //require(msg.sender == shipToOwner[_id]);
    removeTokenFrom(shipToOwner[_id], _id);
    shipToOwner[_id] = _to;
    addTokenTo(_to, _id);
  }

  /**
   * @dev function to put ship on sale
   * @param _id Id of the ship to be put on sale
   * @param _amount the price of the ship
   */
  function priceQuoted(uint _id, uint _amount) public{
    require(msg.sender == shipToOwner[_id]);
    ships[_id].price = _amount;
    ships[_id].forSale = true;
  }

  /**
   * @dev function to remove ship from sale
   * @param _id Id of the ship to be removed from the sale
   */
  function notForSale(uint _id) public {
    require(msg.sender == shipToOwner[_id]);
    ships[_id].forSale = false;
  }

  /**
   * @dev function to buy a ship that is on sale
   * @param _id Id of the ship which the caller wants to buy
   */
  function buy( uint _id) payable public {
    require(msg.value >= priceOfShip(_id));
    require(ships[_id].forSale == true);
    msg.sender.transfer(msg.value - priceOfShip(_id));
    shipToOwner[_id].transfer((95*priceOfShip(_id))/100);
    dev.transfer((5*priceOfShip(_id))/100);
    transferShip(msg.sender,_id);
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}
