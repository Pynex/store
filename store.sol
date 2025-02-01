// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Store is  Ownable {

    address[] public merchants;

    /// @notice buyer => product_id => amount
    mapping (address => mapping(uint => uint)) public Userpurchase;
    /// @notice product_id => quantity
    mapping (uint => uint) public purchaseStatistics;
    mapping (address => bool) public isMecrchant;

    event Purchase(address buyer, uint id, uint quantity, address creator);

    struct Product {
        uint price;
        string productName;
        uint amount;
        uint id;
        address creator;
    } //4732    

    error uAreNotAnOwner();
    error merchantAlreadyAdded();
    error uAreNotAMerchant();
    error notEnoughFunds();
    error ProductsDoesNotExist();
    error incorrectAmount();
    error creatorNotFound();


    modifier merchant() {
        require(isMecrchant[msg.sender], uAreNotAMerchant());
        _;
    }


    Product[] private products;

    error idAlreadyExist();
    error idDoesNotExist();
    error indexNotFound();
    error notEnoughProductsToBuy();
    error arraysMismatch();
    
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
        Product storage product = findProduct(_id);
        product.price = _price; 
    }

    function updateAmount (uint _id, uint _amount) external merchant {
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

    function findCreator(uint _id) internal view returns (address) {
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
        (uint index, bool status) = findIndexById(_id);
        require(!status == false, indexNotFound());

        products[index] = products[products.length-1];
        products.pop();
    }

    function withdraw (uint _money) external payable onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _money, "NotEnoughFunds!");

        payable(owner()).transfer(_money);
    }

    function findIndexById (uint _id) internal view returns (uint, bool) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return (i,true);
            }
         }
         return (0,false);
      }

    function buyProduct (uint _id, uint _quantity) payable public {
        require(getAmount(_id) >= _quantity, notEnoughProductsToBuy());
        require(_quantity != 0, incorrectAmount());
        require(isIdExist(_id) == true,idDoesNotExist());
        require(getPrice(_id) * _quantity <= msg.value, notEnoughFunds());
        uint price = getPrice(_id) * _quantity;
        require(price <= msg.value, notEnoughFunds());

        address creator = getCreator(_id);
        _buyProcess(msg.sender, _id, _quantity, creator);

        uint creatorAmount = price / 100 * 95; 
        uint contractCommission = price - creatorAmount;
        uint change = msg.value - price;

        if (msg.value > price) {
            payable(creator).transfer(creatorAmount);
            payable(address(this)).transfer(contractCommission);
            payable(msg.sender).transfer(change);
        } else {
            payable(creator).transfer(creatorAmount);
            payable(address(this)).transfer(contractCommission);
        }
    } 

    function _buyProcess (address _buyer, uint _id, uint _quantity,address _creator) internal {
        Product storage product = findProduct(_id);
        product.amount -= _quantity;

        Userpurchase[_buyer][_id] += _quantity;
        purchaseStatistics[_id += _quantity];

        emit Purchase(_buyer, _id, _quantity, _creator);
    }

    /// @notice creator => totalAmount
    /// @dev Stores the total amount of funds owed to each creator for their products in the current batch buy operation.
    mapping(address => uint) public creatorsAmount;

    /// @notice product_id => creator
    /// @dev Stores the address of the creator for each product id in the current batch buy operation.
    mapping(uint => address) public idToCreators;

    function batchBuy(uint[] calldata _ids, uint[] calldata _quantities) payable public {
        require(_ids.length == _quantities.length, arraysMismatch());

        uint totalPrice = 0;

        for(uint i = 0; i < _ids.length; i++) {
            require(_quantities[i]>0,incorrectAmount());
            require(getAmount(_ids[i]) >= _quantities[i], notEnoughProductsToBuy());
            totalPrice += getPrice(_ids[i]) * getAmount(_quantities[i]);

            address creator = getCreator(_ids[i]); 
           idToCreators[_ids[i]] = creator;
           creatorsAmount[creator] += (getPrice(_ids[i]) * _quantities[i])/100*95;

        }
        require(totalPrice <= msg.value, notEnoughFunds());

        for (uint i = 0; i < _ids.length; i++) {
            _buyProcess(msg.sender, _ids[i], _quantities[i],findCreator(_ids[i]));

        }
 
        
        if (msg.value > totalPrice) {
            for(uint i = 0; i <_ids.length; i++) {
                if(idToCreators[_ids[i]] != address(0)){
                   payable (idToCreators[_ids[i]]).transfer(creatorsAmount[idToCreators[_ids[i]]]);
                }
            }
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }
    


    function getProducts () public view returns (Product[] memory) {
        require(products.length != 0, ProductsDoesNotExist());
        return products;
    }

    function refund (uint _id, uint _amount) public {
        require(_amount != 0, incorrectAmount());
        require(isIdExist(_id) == true,idDoesNotExist());
        require(Userpurchase [msg.sender][_id] > _amount, incorrectAmount());

        address creator = findCreator(_id);

        payable (creator).transfer((getPrice(_id)* _amount)/100*95);
        payable (address(this)).transfer((getPrice(_id)* _amount)/20);
        Userpurchase[msg.sender][_id] -= _amount;

    }
}

        //### add refund ###
        //add topsellingProducts
        //add getAllPurchase(address)
        //add discountForProducts functionality
        //add fees for merchants and withdraw money for purcchases inst in their address
        //add blackjack and bitches
    
