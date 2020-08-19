pragma solidity ^0.6.2;

import '../coffeecore/Ownable.sol';
import '../coffeeaccesscontrol/DistributorRole.sol';
import '../coffeeaccesscontrol/ConsumerRole.sol';
import '../coffeeaccesscontrol/RetailerRole.sol';
import '../coffeeaccesscontrol/FarmerRole.sol';

// Define a contract 'Supplychain'
contract SupplyChain is Ownable, DistributorRole, ConsumerRole, RetailerRole, FarmerRole {

  // Define 'owner'
  address payable owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
    }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable originFarmerID; // Metamask-Ethereum address of the Farmer
    string originFarmName; // Farmer Name
    string originFarmInformation;  // Farmer Information
    string originFarmLatitude; // Farm Latitude
    string originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID potentially a combination of upc + sku
    string productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint upc);
  event Processed(uint upc);
  event Packed(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address,"Address is inconsistent"); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price,"balance is not enough"); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].consumerID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested,"Item is not harvested");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed,"Item is not processed");
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed,"Item is not packed");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale,"Item is not sale");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold,"Item is not sold");
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped,"Item is not shipped");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received,"Item is not received");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased,"Item is not purchased");
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(owner);
    }
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(uint _upc, address payable _originFarmerID, string memory  _originFarmName, string memory  _originFarmInformation, string memory   _originFarmLatitude, 
  string memory   _originFarmLongitude, string memory   _productNotes) onlyFarmer public 
  {
    // Add the new item as part of Harvest
    items[_upc].sku = sku;
    items[_upc].upc = _upc;
    items[_upc].ownerID = _originFarmerID; 
    items[_upc].originFarmerID = _originFarmerID;
    items[_upc].originFarmName = _originFarmName;
    items[_upc].originFarmInformation = _originFarmInformation;
    items[_upc].originFarmLatitude = _originFarmLatitude;
    items[_upc].originFarmLongitude = _originFarmLongitude;
    items[_upc].productID = _upc + sku;
    items[_upc].productNotes = _productNotes;
    items[_upc].itemState = State.Harvested;

    // Increment sku
    sku = sku + 1;
    upc = _upc;
    // Emit the appropriate event
    emit Harvested(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) harvested(upc) onlyFarmer public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Processed;

    emit Processed(_upc);
    // Emit the appropriate event
    
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) processed(upc) onlyFarmer public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    // Update the appropriate fields
    items[_upc].itemState = State.Packed;

    emit Packed(_upc);
    
    // Emit the appropriate event
    
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) packed(upc) onlyFarmer public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    
    // Emit the appropriate event
    items[_upc].itemState = State.ForSale;
    items[_upc].productPrice = _price;

    emit ForSale(_upc);
    
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) forSale(upc) paidEnough(items[_upc].productPrice) checkValue(_upc) public payable 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Call modifer to check if buyer has paid enough
    
    // Call modifer to send any excess ether back to buyer
    
    {
    
    // Update the appropriate fields - ownerID, distributorID, itemState
    
    // Transfer money to farmer
    
    // emit the appropriate event
    items[_upc].itemState = State.Sold;
    items[_upc].ownerID = msg.sender;
    items[_upc].distributorID = msg.sender;
    items[_upc].originFarmerID.transfer(msg.value);

    emit Sold(_upc);
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) sold(upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Call modifier to verify caller of this function
    
    {
    // Update the appropriate fields
    items[_upc].itemState = State.Shipped;
    
    emit Shipped(_upc);
    // Emit the appropriate event
    
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) shipped(upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    items[_upc].itemState = State.Received;
    items[_upc].ownerID = msg.sender;
    items[_upc].retailerID = msg.sender;
    
    // Emit the appropriate event
    emit Received(_upc);
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
     items[_upc].itemState = State.Purchased;
     items[_upc].consumerID = msg.sender;
     items[_upc].ownerID = msg.sender;
    // Emit the appropriate event
    emit Purchased(_upc);
    
  }


  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string memory  originFarmName,
  string memory   originFarmInformation,
  string memory   originFarmLatitude,
  string memory   originFarmLongitude
  ) 
  {
  // Assign values to the 8 parameters
    itemSKU = items[_upc].sku;
  itemUPC = items[_upc].upc;
  ownerID = items[_upc].ownerID;
  originFarmerID = items[_upc].originFarmerID;
  originFarmName = items[_upc].originFarmName;
  originFarmInformation = items[_upc].originFarmInformation;
  originFarmLatitude = items[_upc].originFarmLatitude;
  originFarmLongitude = items[_upc].originFarmLongitude;


  return 
  (
     itemSKU,
     itemUPC,
     ownerID,
     originFarmerID,
     originFarmName,
     originFarmInformation,
     originFarmLatitude,
     originFarmLongitude
  );
  }

 
  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string memory   productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  ) 
  {
    // Assign values to the 9 parameters
  itemSKU = items[_upc].sku;
  itemUPC = items[_upc].upc;
  productID = items[_upc].productID;
  productNotes = items[_upc].productNotes;
  productPrice = items[_upc].productPrice;
  itemState = uint(items[_upc].itemState);
  distributorID = items[_upc].distributorID;
  retailerID = items[_upc].retailerID;
  consumerID = items[_upc].consumerID;
    
  return 
  (
  itemSKU,
  itemUPC,
  productID,
  productNotes,
  productPrice,
  itemState,
  distributorID,
  retailerID,
  consumerID
  );
  }
}
