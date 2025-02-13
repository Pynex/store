// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Store Contract for Managing Products and Purchases
/// @author Pynex
/// @notice This contract allows adding products, managing discounts, and making purchases.
contract Store is  Ownable {

    address[] public merchants;

    /// @notice buyer => product_id => amount
    mapping (address => mapping(uint => uint)) public Userpurchase;
    /// @notice product_id => quantity
    mapping (uint => uint) public purchaseStatistics;
    /// @notice merchant address => isMerchant?(true,false)
    mapping (address => bool) public isMecrchant;
    /// @notice merchant => totalSales
    mapping (address => uint) public amountOfSales;
    /// @notice user => balance
    mapping (address => uint) public userBalance;
    /// @notice user => FundsBlocked?
    mapping (address => bool) public areUsersFundsBlocked;
    /// @notice user => HowMuchFundsBlocked
    mapping (address => uint) public FundsBlocked;
    /// @notice user => block.timestamp + delayTime
    mapping (address => uint) public unlockTime;
    /// @notice user => product_id => discount(in %) => amount
    mapping (address => DiscountTicket[]) public discountTicketForUser;
    uint public delayTime = 20 hours;

    event Purchase(address buyer, uint id, uint quantity, address creator, uint price);
    event Refund(address buyer,uint id, uint amount,address creator, uint price);

    struct Product {
        uint price;
        string productName;
        uint amount;
        uint id;
        address creator;
    }

    struct DiscountTicket {
        uint discount;
        uint amount;
        uint id;
        address user;
    }

    error uAreNotAnOwner();
    error merchantAlreadyAdded();
    error uAreNotAMerchant();
    error ticketIndexNotFound();
    error notEnoughFunds();
    error ProductsDoesNotExist();
    error incorrectAmount();
    error creatorNotFound();
    error discountCantBeMoreThen100();
    error discountCantBeEqZero();
    error MerchantsDoesNotExist();
    error yourFundsBlocked();
    error userDoesNotHaveTicket();
    error incorrectShoppingCart();


    modifier merchant() {
        require(isMecrchant[msg.sender], uAreNotAMerchant());
        _;
    }
    DiscountTicket[] private discountTickets;
    Product[] private products;

    error idAlreadyExist();
    error idDoesNotExist();
    error indexNotFound();
    error notEnoughProductsToBuy();
    error writeCorrectAmount();
    error arraysMismatch();
    error incorrectAddress();
    error incorrectDeposit();
    error youAreNotCreater();
    
    function depositBalance() public payable {
        require(msg.value > 0, incorrectDeposit());
        userBalance[msg.sender] += msg.value;
    }
    function getMerchants () external view returns (address[] memory) {
        require(merchants.length != 0, MerchantsDoesNotExist());
        return merchants;
    }
    function addDiscountTicket (uint _discount, uint _id, uint _amount,address _user) public merchant {
        require(isIdExist(_id) == true,idDoesNotExist());
        require(_user != address(0),incorrectAddress());
        require(_discount <= 100, discountCantBeMoreThen100());
        require(_discount > 0, discountCantBeEqZero());
        require(msg.sender == getCreator(_id), youAreNotCreater());

        DiscountTicket memory newTicket = DiscountTicket({
            discount: _discount,
            amount: _amount,
            id: _id,
            user: _user
        });

        discountTicketForUser[_user].push(newTicket);
    }

    function findDiscountTickets(address _user) public view returns(DiscountTicket[] memory) {
        DiscountTicket[] memory userTickets = discountTicketForUser[_user];
        DiscountTicket[] memory result = new DiscountTicket[](userTickets.length);
        for(uint i = 0; i < userTickets.length; i++) {
                result[i] = userTickets[i]; 
            }
        return result;
    }

    function getDiscount(address _user,uint _id) public view returns (uint) {
        DiscountTicket[] memory userTickets = discountTicketForUser[_user];
        uint discountValue = 0;

        for (uint i = 0; i < userTickets.length; i++) {
             if (userTickets[i].id == _id) {
                discountValue = userTickets[i].discount;
                break;
            }
        }
        return discountValue;
    }

    function getDisAmount(address _user,uint _id) public view returns (uint) {
        DiscountTicket[] memory userTickets = discountTicketForUser[_user];
        uint amount = 0;

        for (uint i = 0; i < userTickets.length; i++) {
             if (userTickets[i].id == _id) {
                amount = userTickets[i].amount;
                break;
            }
        }
        return amount;
    }

    function getBalance() public view returns (uint) {
        return (userBalance[msg.sender]);
    }

    function getBlockedBalance (address _user) public view returns (uint) {
        return (FundsBlocked[_user]);
    }

    function addMerchant (address _merchant) public onlyOwner {
        require(isMecrchant[_merchant] != true, merchantAlreadyAdded());
        merchants.push(_merchant);
        isMecrchant[_merchant] = true;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}


    function addProduct (uint _price, string calldata _productName, uint _amount, uint _id) public merchant {
        require(!isIdExist(_id), idAlreadyExist());
        address _creator = msg.sender;
        products.push(Product(_price, _productName, _amount,_id, _creator));
        
    }

    function updatePrice (uint _id, uint _price) external merchant {
        require(msg.sender == getCreator(_id), youAreNotCreater());
        Product storage product = findProduct(_id);
        product.price = _price;
    }

    function updateAmount (uint _id, uint _amount) external merchant {
        require(msg.sender == getCreator(_id), youAreNotCreater());
        Product storage product = findProduct(_id);
        product.amount = _amount;
    }

    function getPrice (uint _id) public view returns (uint) {
        Product storage product = findProduct(_id);
        return (product.price);
    }

    function getAmount (uint _id) public view returns (uint) {
        Product storage product = findProduct(_id);
        return (product.amount);
    }

    function findProduct(uint _id) internal view returns(Product storage product) {
        for(uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return products[i];
            }
        }
        revert indexNotFound();
    }

    function getCreator(uint _id) public view returns(address) {
        Product storage product = findProduct(_id);
        return (product.creator);
    }

    function findCreator(uint _id) public view returns (address) {
        require(isIdExist(_id) == true,idDoesNotExist());
        for (uint i = 0;i <products.length; i++) {
            if (products[i].id == _id) {
                return products[i].creator;
            }
        }
        revert creatorNotFound();
        
    }

    function isIdExist (uint _id) internal view returns(bool) {
        for (uint i = 0; i < products.length; i++) {
                if(products[i].id == _id) {
                    return true;
                }
        }
        return false;
    }

    function deleteProduct (uint _id) external merchant {
        require(isIdExist(_id) == true, idDoesNotExist());
        require(msg.sender == getCreator(_id), youAreNotCreater());
        (uint index, bool status) = findIndexById(_id);
        require(!status == false, indexNotFound());

        products[index] = products[products.length-1];
        products.pop();
    }

    function deleteDiscountTicketForUser(uint _id, address _user) internal {
    
        DiscountTicket[] storage userTickets = discountTicketForUser[_user];

        require(userTickets.length != 0, userDoesNotHaveTicket());

        uint index = findIndexForDiscountTicketByIndex(_id, _user);

            if (index != userTickets.length - 1) {
                userTickets[index] = userTickets[userTickets.length - 1];
            }

        userTickets.pop();
    }

    function updateBlockedFunds () public {
        changeStatusAndUnblockFunds(msg.sender);
    }

    function withdraw (uint _money) public payable {
        uint balance = address(this).balance;
        uint fee = 5; //5%
        changeStatusAndUnblockFunds(msg.sender);

        require(balance >= _money, "NotEnoughFunds!");
        require(_money <= userBalance[msg.sender]);
        //                          1000 - 1000/10*5
        payable(msg.sender).transfer(_money - _money/100*fee);
        userBalance[msg.sender] -= _money;
        userBalance[owner()] += _money/100*fee;
    }

    function findIndexById (uint _id) internal view returns (uint, bool) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return (i,true);
            }
         }
         return (0,false);
    }

    function findIndexForDiscountTicketByIndex(uint _id, address _user) internal view returns (uint) {
    
        DiscountTicket[] memory userTickets = findDiscountTickets(_user);

        require(userTickets.length != 0, userDoesNotHaveTicket());

        for (uint i = 0; i < userTickets.length; i++) {
            if (userTickets[i].id == _id) {
                return i;
            }
        }
    
        revert ticketIndexNotFound();
    }

    function buyProduct (uint _id, uint _quantity,uint _useDiscount) public {
        require(getAmount(_id) >= _quantity, notEnoughProductsToBuy());
        require(_quantity != 0, incorrectAmount());
        require(isIdExist(_id) == true,idDoesNotExist());
        require(getPrice(_id) * _quantity <= userBalance[msg.sender], notEnoughFunds());
        require(_useDiscount < 2);
        uint totalPrice = getPrice(_id) * _quantity;
        address user = msg.sender;
        address creator = getCreator(_id);
        
        if (_useDiscount == 1) {
            require(_quantity == getDisAmount(user,_id), writeCorrectAmount());
            uint discount = getDiscount(user, _id);
            
            uint disTotalPrice = totalPrice - totalPrice/100*discount;

            _buyProcess(msg.sender, _id, _quantity, creator, getPrice(_id));

            FundsBlocked[creator] += disTotalPrice;
            userBalance[msg.sender] -= disTotalPrice;
            deleteDiscountTicketForUser(_id, user);

        } else {

            _buyProcess(msg.sender, _id, _quantity, creator, getPrice(_id));

            FundsBlocked[creator] += totalPrice;
            userBalance[user] -=totalPrice;
        }
    } 

    function setActivationTime (address _user) internal {
        unlockTime[_user] = block.timestamp + delayTime;
        areUsersFundsBlocked[_user] = true;
    }

    function changeStatusAndUnblockFunds (address _user) internal  {
        if (block.timestamp > unlockTime[_user]) {
            areUsersFundsBlocked[_user] = false;
            uint totalFunds = getBlockedBalance(_user);
            userBalance[_user] += totalFunds;
            FundsBlocked[_user] -= totalFunds;
        }
    }

    function prematureUnblockingFunds (address _user) public onlyOwner {
        areUsersFundsBlocked[_user] = false;
    }

    function _buyProcess (address _buyer, uint _id, uint _quantity,address _creator,uint _price) internal {
        Product storage product = findProduct(_id);
        product.amount -= _quantity;

        Userpurchase[_buyer][_id] += _quantity;
        purchaseStatistics[_id] += _quantity;

        uint totalPrice = _quantity*_price;
        amountOfSales[_creator] += totalPrice;

        emit Purchase(_buyer, _id, _quantity, _creator, _price);

        
        setActivationTime(_creator);
    }
    
    function _refundProcess (address _buyer, uint _id, uint _amount,address _creator, uint _price) internal {
        Product storage product = findProduct(_id);
        product.amount += _amount;

        Userpurchase[_buyer][_id] -= _amount;
        purchaseStatistics[_id] -= _amount;

        uint totalPrice = _amount*_price;
        amountOfSales[_creator] -= totalPrice;

        emit Refund(_buyer,_id,_amount, _creator, _price);

        setActivationTime(_buyer);
        setActivationTime(_creator);
    }
   
    function batchBuy(uint[] calldata _ids, uint[] calldata _quantities, uint[] calldata _useDiscount) public {
        require(_ids.length == _quantities.length , arraysMismatch());
        require(_ids.length == _useDiscount.length, arraysMismatch());
        uint totalPrice = 0;
        for(uint i = 0; i < _ids.length; i++) {
            require(_quantities[i]>0,incorrectAmount());
            require(getAmount(_ids[i]) >= _quantities[i], notEnoughProductsToBuy());
            address creator = getCreator(_ids[i]);
            uint price = getPrice(_ids[i]) * _quantities[i];

            if (_useDiscount[i] == 1) {
                require(_quantities[i] == getDisAmount(msg.sender, _ids[i]), writeCorrectAmount());
                uint discount = getDiscount(msg.sender, _ids[i]);
                price = price - (price / 100 * discount); 
                deleteDiscountTicketForUser(_ids[i], msg.sender);
            }

            _buyProcess(msg.sender, _ids[i], _quantities[i], creator, price);

            totalPrice += price;

            FundsBlocked[creator] += price;
            userBalance[msg.sender] -=price;

        }
        require(totalPrice <= userBalance[msg.sender], notEnoughFunds());
    }
    
    function getTopPurchasedProduct () public view returns (uint) {
        uint maxAmount = 0;
        uint id = 0;
        if (products.length == 0) {
            return 0;
        }
        for (uint i = 0; i < products.length; i++) {
            uint currentId = products[i].id;
            uint currentAmount = purchaseStatistics[currentId]; 
            
        
            if(currentAmount > maxAmount) { //кол-во покупок в маппинге purchaseStatistics с количеством покупок с других товаров(0->5->20)
                maxAmount = currentAmount;
                id = currentId;
                
            }
        }
        return id;
    }

    function getBestMerchant () public view returns (address) {
        uint totalSales = 0;
        address merchantik = address(0);
        

        for (uint i = 0; i < merchants.length; i++) {
            address currentMerchant = merchants[i];
            uint currentTotalSales = amountOfSales[currentMerchant];

            if (currentTotalSales > totalSales) {
                totalSales = currentTotalSales;
                merchantik = currentMerchant;
            }
        }
        return merchantik;
    }


    function getProducts () external  view returns (Product[] memory) {
        require(products.length != 0, ProductsDoesNotExist());
        return products;
    }
    function getProductById(uint _id) external view returns (Product memory) {
        require(products.length != 0, ProductsDoesNotExist());

        for (uint i = 0; i <products.length; i++) {
            if(products[i].id == _id) {
                return products[i];
            }
        }
        revert("ProductNotFound");
    }

    function refund (uint _id, uint _amount) public {
        require(_amount != 0, incorrectAmount());
        require(isIdExist(_id) == true,idDoesNotExist());
        require(Userpurchase [msg.sender][_id] >= _amount, incorrectAmount());

        address creator = getCreator(_id);
        uint price = getPrice(_id);
        address _buyer = msg.sender;
        uint refundAmount = price*_amount;

        _refundProcess(_buyer, _id, _amount, creator, price);

        FundsBlocked[msg.sender] += refundAmount;
        FundsBlocked[creator] -=refundAmount;
    }
}
