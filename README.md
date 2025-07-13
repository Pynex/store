# Store Contract Documentation

## Overview

The Store contract is a decentralized marketplace smart contract that enables merchants to sell products, manage inventory, handle discounts, and process purchases with built-in refund mechanisms. The contract implements a time-locked fund release system for security and includes comprehensive merchant management.

**Contract Details:**
- **License:** MIT
- **Solidity Version:** ^0.8.28
- **Author:** Pynex
- **Inheritance:** OpenZeppelin Ownable

## Core Features

### 1. Product Management
- Add, update, and delete products
- Inventory tracking
- Price management
- Creator verification

### 2. Merchant System
- Merchant registration and verification
- Sales tracking
- Performance analytics

### 3. Discount System
- Create discount tickets for specific users
- Percentage-based discounts
- Usage tracking and validation

### 4. Purchase System
- Individual and batch purchases
- Discount application
- Purchase statistics

### 5. Fund Management
- User balance tracking
- Time-locked fund release (20 hours default)
- Withdrawal system with fees
- Refund mechanism

### 6. Security Features
- Fund blocking during transactions
- Time-delayed fund release
- Owner override for emergency fund release

## Data Structures

### Product Struct
```solidity
struct Product {
    uint price;        // Price per unit
    string productName; // Product name
    uint amount;       // Available quantity
    uint id;           // Unique product identifier
    address creator;   // Merchant who created the product
}
```

### DiscountTicket Struct
```solidity
struct DiscountTicket {
    uint discount;     // Discount percentage (1-100)
    uint amount;       // Quantity eligible for discount
    uint id;           // Product ID
    address user;      // User who can use this ticket
}
```

## State Variables

### Mappings
- `Userpurchase`: buyer → product_id → amount purchased
- `purchaseStatistics`: product_id → total quantity sold
- `isMecrchant`: merchant address → is merchant boolean
- `amountOfSales`: merchant → total sales amount
- `userBalance`: user → balance amount
- `areUsersFundsBlocked`: user → funds blocked status
- `FundsBlocked`: user → amount of blocked funds
- `unlockTime`: user → timestamp when funds unlock
- `discountTicketForUser`: user → array of discount tickets

### Arrays
- `merchants`: List of all registered merchants
- `products`: List of all products
- `discountTickets`: Internal discount tickets array

### Constants
- `delayTime`: 20 hours (fund release delay)

## Events

### Purchase Event
```solidity
event Purchase(address buyer, uint id, uint quantity, address creator, uint price);
```
Emitted when a purchase is made.

### Refund Event
```solidity
event Refund(address buyer, uint id, uint amount, address creator, uint price);
```
Emitted when a refund is processed.

## Functions

### Administration Functions

#### `addMerchant(address _merchant)`
- **Access:** Owner only
- **Purpose:** Add a new merchant to the platform
- **Requirements:** Merchant must not already exist

#### `prematureUnblockingFunds(address _user)`
- **Access:** Owner only
- **Purpose:** Emergency fund release for users
- **Requirements:** User must have blocked funds

### Merchant Functions

#### `addProduct(uint _price, string calldata _productName, uint _amount, uint _id)`
- **Access:** Merchants only
- **Purpose:** Add a new product to the store
- **Requirements:** Product ID must be unique
- **Parameters:**
  - `_price`: Price per unit
  - `_productName`: Product name
  - `_amount`: Initial quantity
  - `_id`: Unique product identifier

#### `updatePrice(uint _id, uint _price)`
- **Access:** Product creator only
- **Purpose:** Update product price
- **Requirements:** Caller must be the product creator

#### `updateAmount(uint _id, uint _amount)`
- **Access:** Product creator only
- **Purpose:** Update product quantity
- **Requirements:** Caller must be the product creator

#### `deleteProduct(uint _id)`
- **Access:** Product creator only
- **Purpose:** Remove product from store
- **Requirements:** Product must exist, caller must be creator

#### `addDiscountTicket(uint _discount, uint _id, uint _amount, address _user)`
- **Access:** Merchants only
- **Purpose:** Create discount ticket for specific user
- **Requirements:** 
  - Product must exist
  - Discount between 1-100%
  - Caller must be product creator
  - Valid user address

### User Functions

#### `depositBalance()`
- **Access:** Public payable
- **Purpose:** Deposit ETH to user balance
- **Requirements:** Must send ETH with transaction

#### `buyProduct(uint _id, uint _quantity, uint _useDiscount)`
- **Access:** Public
- **Purpose:** Purchase a single product
- **Parameters:**
  - `_id`: Product ID
  - `_quantity`: Quantity to purchase
  - `_useDiscount`: 0 = no discount, 1 = use discount
- **Requirements:**
  - Sufficient product quantity
  - Sufficient user balance
  - Valid discount ticket (if using discount)

#### `batchBuy(uint[] calldata _ids, uint[] calldata _quantities, uint[] calldata _useDiscount)`
- **Access:** Public
- **Purpose:** Purchase multiple products in one transaction
- **Requirements:**
  - Array lengths must match
  - Sufficient quantities and balance for all products
  - Valid discount tickets (if using discounts)

#### `refund(uint _id, uint _amount)`
- **Access:** Public
- **Purpose:** Refund a previous purchase
- **Requirements:**
  - Must have purchased the product
  - Sufficient purchase amount to refund
  - Valid product ID

#### `withdraw(uint _money)`
- **Access:** Public payable
- **Purpose:** Withdraw funds from user balance
- **Requirements:**
  - Sufficient balance
  - Sufficient contract balance
- **Fee:** 5% fee deducted, sent to contract owner

#### `updateBlockedFunds()`
- **Access:** Public
- **Purpose:** Update blocked funds status and release if time passed
- **Effect:** Automatically releases funds if delay time has passed

### View Functions

#### `getProducts()`
- **Returns:** Array of all products
- **Requirements:** Products must exist

#### `getProductById(uint _id)`
- **Returns:** Specific product by ID
- **Requirements:** Product must exist

#### `getMerchants()`
- **Returns:** Array of all merchant addresses
- **Requirements:** Merchants must exist

#### `getBalance()`
- **Returns:** Caller's current balance

#### `getBlockedBalance(address _user)`
- **Returns:** User's blocked funds amount

#### `getPrice(uint _id)`
- **Returns:** Product price

#### `getAmount(uint _id)`
- **Returns:** Available product quantity

#### `getCreator(uint _id)`
- **Returns:** Product creator address

#### `getDiscount(address _user, uint _id)`
- **Returns:** Discount percentage for user and product

#### `getDisAmount(address _user, uint _id)`
- **Returns:** Discounted quantity available to user

#### `findDiscountTickets(address _user)`
- **Returns:** Array of user's discount tickets

#### `getTopPurchasedProduct()`
- **Returns:** Product ID with highest sales

#### `getBestMerchant()`
- **Returns:** Merchant address with highest sales

## Error Handling

The contract includes comprehensive error handling with custom errors:

- `uAreNotAnOwner()`: Caller is not the owner
- `merchantAlreadyAdded()`: Merchant already exists
- `uAreNotAMerchant()`: Caller is not a merchant
- `notEnoughFunds()`: Insufficient funds
- `ProductsDoesNotExist()`: No products available
- `incorrectAmount()`: Invalid amount specified
- `discountCantBeMoreThen100()`: Discount exceeds 100%
- `yourFundsBlocked()`: User funds are blocked
- `idAlreadyExist()`: Product ID already exists
- `idDoesNotExist()`: Product ID not found
- `notEnoughProductsToBuy()`: Insufficient product quantity
- `arraysMismatch()`: Array parameters don't match
- `incorrectDeposit()`: Invalid deposit amount

## Security Considerations

### 1. Fund Locking Mechanism
- Funds are locked for 20 hours after purchase/refund
- Prevents immediate fund extraction
- Owner can override in emergencies

### 2. Access Control
- Owner-only functions for critical operations
- Merchant verification system
- Creator-only product management

### 3. Input Validation
- Comprehensive parameter validation
- Array length matching for batch operations
- Discount percentage limits (1-100%)

### 4. Reentrancy Protection
- Uses internal functions for critical operations
- State changes before external calls
- Proper fund management

## Usage Examples

### Adding a Product
```solidity
// Must be called by a registered merchant
store.addProduct(1000, "Gaming Laptop", 10, 1);
```

### Making a Purchase
```solidity
// Deposit funds first
store.depositBalance{value: 1 ether}();

// Purchase without discount
store.buyProduct(1, 2, 0);

// Purchase with discount (if available)
store.buyProduct(1, 1, 1);
```

### Batch Purchase
```solidity
uint[] memory ids = [1, 2, 3];
uint[] memory quantities = [1, 2, 1];
uint[] memory useDiscounts = [0, 1, 0];

store.batchBuy(ids, quantities, useDiscounts);
```

### Creating Discount Tickets
```solidity
// 20% discount for 5 units of product 1 for specific user
store.addDiscountTicket(20, 1, 5, userAddress);
```

## Fee Structure

- **Withdrawal Fee:** 5% of withdrawn amount
- **Fee Recipient:** Contract owner
- **No fees on:** Deposits, purchases, refunds

## Time Delays

- **Fund Release Delay:** 20 hours after purchase/refund
- **Override Authority:** Contract owner can release funds early
- **Automatic Release:** Users can call `updateBlockedFunds()` after delay