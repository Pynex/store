import { contracts } from "../typechain-types";
import { loadFixture, ethers, expect } from "./setup";
import { Product,DiscountTicket } from "./StoreTypes";

describe("Store", function() {
        let owner: any;
        let merchant1: any;
        let merchant2: any;
        let user1: any;
        let storeContract: any;
        
        
        before(async function(){
        [owner, merchant1, merchant2, user1] =   await ethers.getSigners()

            
            const Store = await ethers.getContractFactory("Store")
            storeContract = await Store.deploy(owner.address)
            await storeContract.waitForDeployment()
            console.log("Contract address:", storeContract.target) 
        })

        it("another0",async function(){
            await storeContract.getTopPurchasedProduct()
        })

        it ("should correctly add new merchant", async function () {
            const newMerchant = merchant1.address
            await storeContract.connect(owner).addMerchant(newMerchant)
            const merchants = await storeContract.getMerchants()
            expect(merchants.length).to.eq(1)
            expect(merchants).to.include(newMerchant)
        })

        it ("should revert if non-owner tries add a merchant", async function(){
            const newMerchant = merchant1.address
            await expect(storeContract.connect(merchant1).addMerchant(newMerchant)).to.be.reverted
        })

       it ("should correctly add new product", async function(){
        const newProduct: Product = {
            name: "Phone",
            id: 1,
            price: 150000,
            amount: 15,
            creator: merchant1.address
        }
        
        await storeContract.connect(merchant1).addProduct(newProduct.price, newProduct.name, newProduct.amount, newProduct.id)
        
        const Products = await storeContract.getProducts()
        expect(Products.length).to.be.greaterThan(0)
        const createdProduct = await storeContract.getProductById(newProduct.id)

        const creator = await storeContract.findCreator(newProduct.id)
        
        expect(createdProduct[2]).to.eq(newProduct.amount)
        expect(createdProduct[3]).to.eq(newProduct.id)
        expect(createdProduct[0]).to.eq(newProduct.price)
        expect(creator).to.eq(newProduct.creator)
        expect(createdProduct[1]).to.eq(newProduct.name)
       })

       it("should correctly deposit balance", async function(){
        const amount = ethers.parseEther("0.5")

        await storeContract.connect(user1).depositBalance({value:amount})
        const balance = await storeContract.connect(user1).getBalance()
        expect(balance).to.eq(amount)
       })

       it("should correctly add discount Ticket", async function(){
        const newTicket: DiscountTicket = {
            discount: 50,
            amount: 5,
            id:1,
            user: user1.address
        }
        await storeContract.connect(merchant1).addDiscountTicket(newTicket.discount, newTicket.id, newTicket.amount, newTicket.user)
        const disTicket = await storeContract.findDiscountTickets(user1.address)
        console.log(disTicket)
        const thisTicket = disTicket[0]
        const dis = await storeContract.getDiscount(newTicket.user, newTicket.id)
        const am = await storeContract.getDisAmount(newTicket.user, newTicket.id)
        expect(dis).to.eq(newTicket.discount)
        expect(am).to.eq(newTicket.amount)
        expect(thisTicket[2]).to.eq(newTicket.id)
        expect(thisTicket[3]).to.eq(newTicket.user)
       })

       it("should correctly update price and amount,get new price and new amount", async function(){
        const newPrice = 250000
        const newAmount = 3
        const cId = 1

        await storeContract.connect(merchant1).updatePrice(cId, newPrice)
        await storeContract.connect(merchant1).updateAmount(cId, newAmount)
        const newPPrice = await storeContract.connect(merchant1).getPrice(cId)
        const newAAmount = await storeContract.connect(merchant1).getAmount(cId)

        expect(newPrice).to.eq(newPPrice)
        expect(newAmount).to.eq(newAAmount)
       })

    it("correctly delete product",async function(){
        const newProduct: Product = {
            name: "Phone",
            id: 2,
            price: 100,
            amount: 5,
            creator: merchant1.address
        }
        
        await storeContract.connect(merchant1).addProduct(newProduct.price, newProduct.name, newProduct.amount, newProduct.id)
        await storeContract.connect(merchant1).deleteProduct(newProduct.id)
        const Products = await storeContract.getProducts()
        expect(Products.length).to.eq(1)
    })

    it("should correctly buy product",async function(){
        const initialUser1Balance  = await storeContract.connect(user1).getBalance()
        const newProduct: Product = {
            name: "ELONPhone",
            id: 3,
            price: 10000000,
            amount: 10,
            creator: merchant1.address
        }
        const pId = 3
        //quantities of products that the user wants to buy
        const pAmount = 3
        
        await storeContract.connect(merchant1).addProduct(newProduct.price, newProduct.name, newProduct.amount, newProduct.id)
        
        const buyTx = await storeContract.connect(user1).buyProduct(pId, pAmount, 0)
        const cAmount = await storeContract.getAmount(3)
        expect(cAmount).to.eq(7)

        const newUser1Balance = await storeContract.connect(user1).getBalance()
        const firstProductPrice = await storeContract.getPrice(3)
        
        await expect(newUser1Balance).to.eq(initialUser1Balance-firstProductPrice*3n)
        await expect(buyTx).to.emit(storeContract, 'Purchase').withArgs(user1.address, newProduct.id,pAmount,newProduct.creator,
            newProduct.price)
    })

    it("should correctly buy product with discount ticket", async function(){

        //logs
        console.log("Starting test...");
        console.log("Owner address:", owner.address);
        console.log("Merchant2 address:", merchant2.address);
        console.log("User1 address:", user1.address); 
        console.log("Contract address:", storeContract.target);

        //get the initials balances
        const initialUser1Balance  = await storeContract.connect(user1).getBalance()
        const initiaBlockedMerchantBalance  = await storeContract.connect(merchant2).getBlockedBalance(merchant2)

        //create new product
        const newProduct: Product = {
            name: "Computer",
            id: 812,
            price: 5000000,
            amount: 15,
            creator: merchant2.address
        }
        //add merchant
        await storeContract.connect(owner).addMerchant(merchant2)
        await storeContract.connect(merchant2).addProduct(newProduct.price, newProduct.name, newProduct.amount, newProduct.id)

        //create new discount ticket for user1
        const newTicket: DiscountTicket = {
            discount: 70,
            amount: 5,
            id:812,
            user: user1.address
        }
        await storeContract.connect(merchant2).addDiscountTicket(newTicket.discount, newTicket.id, newTicket.amount, newTicket.user)

        //quantities of products that the user wants to buy
        const pAmount = 5

        //buy product with discount ticket
        const buyTx = await storeContract.connect(user1).buyProduct(812, pAmount, 1)//(x,y,1 => buy product with discount ticket)
        const cAmount = await storeContract.getAmount(812)
        expect(cAmount).to.eq(10)

        //get user balance and check it
        const newUser1Balance = await storeContract.connect(user1).getBalance()
        const productPrice =await storeContract.getPrice(812)
        const productPriceWithDiscount = productPrice/100n*30n //1500000
        //x=y-150000*5
        expect(newUser1Balance).to.eq(initialUser1Balance-productPriceWithDiscount*5n)


        //get and check blocked(because funds at first added in blocked merhant's account) merhcant's balance
        const blockedMerchant2Balance = await storeContract.connect(merchant2).getBlockedBalance(merchant2)
        expect(blockedMerchant2Balance).to.eq(initiaBlockedMerchantBalance+productPriceWithDiscount*5n)

        await expect(buyTx).to.emit(storeContract, 'Purchase').withArgs(user1.address, newProduct.id,pAmount,newProduct.creator,
             productPriceWithDiscount)
    })

    it("should remove the lock of the funds and withdraw funds",async function(){
        //check blocked funds
        const inittialBlockedFunds = await storeContract.getBlockedBalance(merchant2)
        console.log("blockedFunds:", inittialBlockedFunds)

        //rewind time
        await ethers.provider.send("evm_increaseTime", [21 * 60 * 60]);
        await ethers.provider.send("evm_mine", []);

        //check that the funds are unblocked
        await storeContract.connect(merchant2).updateBlockedFunds()
        const newFunds = await storeContract.getBlockedBalance(merchant2)
        console.log("newFunds:", newFunds)
        expect(newFunds).to.eq(0)

        //check merchant2 balance
        const merchant2Balance = await storeContract.connect(merchant2).getBalance()
        console.log("merchant2Balance:",merchant2Balance)
        const initialbalance = await ethers.provider.getBalance(merchant2.address)
        console.log(`Balance of ${user1.address}: ${ethers.formatEther(initialbalance)} ETH`);

        //withdraw funds
        await storeContract.connect(merchant2).withdraw(merchant2Balance)
        const newMerhcant2Balance = await storeContract.connect(merchant2).getBalance()
        console.log("newMerhcant2Balance:",newMerhcant2Balance)
        expect(newMerhcant2Balance).to.eq(0)

        const balance = await ethers.provider.getBalance(merchant2.address)
        console.log(`Balance of ${user1.address}: ${ethers.formatEther(balance)} ETH`);
        const sMBalance = await ethers.provider.getBalance(storeContract.target);
        console.log(`Balance of ${storeContract.target}: ${ethers.formatEther(sMBalance)} ETH`);

    })

    it("should correctly batchBuy with and without discount ticket", async function (){

            //logs
            console.log("Starting test...");
            console.log("Owner address:", owner.address);
            console.log("Merchant2 address:", merchant2.address);
            console.log("Merchant1 address:", merchant1.address);
            console.log("User1 address:", user1.address); 
            console.log("Contract address:", storeContract.target);
            
    
            //get the initials balances
            const initialUser1Balance  = await storeContract.connect(user1).getBalance()
            console.log("initialUser1Balance:",initialUser1Balance)
            const initiaBlockedMerchant2Balance  = await storeContract.connect(merchant2).getBlockedBalance(merchant2)
            const initiaBlockedMerchant1Balance  = await storeContract.connect(merchant1).getBlockedBalance(merchant1)
    
            //create new product
            const newProduct1: Product = {
                name: "sss",
                id: 100,
                price: 151750000,
                amount: 50,
                creator: merchant2.address
            }
            const newProduct2: Product = {
                name: "asd",
                id: 52,
                price: 96315000,
                amount: 15,
                creator: merchant1.address
            }
            await storeContract.connect(merchant2).addProduct(newProduct1.price, newProduct1.name, newProduct1.amount, newProduct1.id)
            await storeContract.connect(merchant1).addProduct(newProduct2.price, newProduct2.name, newProduct2.amount, newProduct2.id)

            
            //create new discount ticket for user1
            const newTicket: DiscountTicket = {
                discount: 50,
                amount: 10,
                id:52,
                user: user1.address
            }
            await storeContract.connect(merchant1).addDiscountTicket(newTicket.discount, newTicket.id, newTicket.amount, newTicket.user)
    
    
            //buy product with discount ticket
            await storeContract.connect(user1).batchBuy(["52","100","812"], ["10","30","10"], ["1","0","0"])//([x],[y],[1 => buy product with discount ticket])
            const cAmount812 = await storeContract.getAmount(812)
            expect(cAmount812).to.eq(0)
            const cAmount52 = await storeContract.getAmount(52)
            expect(cAmount52).to.eq(5)
            const cAmount100 = await storeContract.getAmount(100)
            expect(cAmount100).to.eq(20)

    
            //get user balance and check it
            const newUser1Balance = await storeContract.connect(user1).getBalance()
            console.log("newUser1Balance:",newUser1Balance)
            const productPrice812 =await storeContract.getPrice(812)
            console.log("productPrice812:",productPrice812)
            const productPrice100 = await storeContract.getPrice(100)
            console.log("productPrice100:",productPrice100)
            const productPrice52 = await storeContract.getPrice(52)
            console.log("productPrice52:",productPrice52)
            const productPrice52withDiscount = productPrice52/100n*50n
            console.log("productPrice52withDiscount:",productPrice52withDiscount)
            //totalPrice = 5000000*10+151750000*30+48157500*10 = 5084075000
            const totalPrice = productPrice52withDiscount*10n+productPrice812*10n+productPrice100*30n
            console.log("totalPrice:",totalPrice)
            //499999989362775000 = 499999999962500000-5084075000
            expect(newUser1Balance).to.eq(initialUser1Balance-totalPrice)

            const merchant1Funds = productPrice52withDiscount*10n
            const newBlockedMerhcant1Balance = await storeContract.connect(merchant1).getBlockedBalance(merchant1)
            console.log("initiaBlockedMerchant1Balance:",initiaBlockedMerchant1Balance)
            console.log("newBlockedMerhcant1Balance:",newBlockedMerhcant1Balance)
            console.log("merchant1Funds:",merchant1Funds)
            expect(newBlockedMerhcant1Balance).to.eq(initiaBlockedMerchant1Balance+merchant1Funds)
    
    
            //get and check blocked(because funds at first added in blocked merhant's account) merhcant's balance
            const merhcant2Funds = totalPrice - merchant1Funds
            console.log("initiaBlockedMerchant1Balance:",initiaBlockedMerchant2Balance)
            const newBlockedMerhcant2Balance = await storeContract.connect(merchant2).getBlockedBalance(merchant2)
            console.log("newBlockedMerhcant2Balance:",newBlockedMerhcant2Balance)
            console.log("merhcant2Funds:",merhcant2Funds)
            expect(newBlockedMerhcant2Balance).to.eq(initiaBlockedMerchant2Balance+merhcant2Funds)
        

            //logs
            console.log("Starting test...");
            console.log("Owner address:", owner.address);
            console.log("Merchant2 address:", merchant2.address);
            console.log("Merchant1 address:", merchant1.address);
            console.log("User1 address:", user1.address); 
            console.log("Contract address:", storeContract.target);
    })

    it("should correctly get top purchased products and best merchant",async function(){
        const topProduct = await storeContract.getTopPurchasedProduct()
        console.log("topProduct:",topProduct)
        expect(topProduct).to.eq(100n)

        const bestMerchant = await storeContract.getBestMerchant()
        console.log("bestMerchant:",bestMerchant)
        expect(bestMerchant).to.eq(merchant2.address)
    })

    it("should correctly refund product",async function(){
        const initialBlockedUser1Balance  = await storeContract.connect(user1).getBlockedBalance(user1)
        const initialBlockedMerchantBalance  = await storeContract.connect(merchant2).getBlockedBalance(merchant2)
        console.log("initialUser1Balance:",initialBlockedUser1Balance)
        console.log("initialBlockedMerchantBalance:",initialBlockedMerchantBalance)

        await storeContract.connect(user1).refund(100,1)
        const newBlockedUser1Balance  = await storeContract.connect(user1).getBlockedBalance(user1)
        const newBlockedMerchantBalance  = await storeContract.connect(merchant2).getBlockedBalance(merchant2)
        console.log("newBlockedMerchantBalance:",newBlockedMerchantBalance)
        expect(initialBlockedMerchantBalance).to.eq(newBlockedMerchantBalance+151750000n)
        expect(initialBlockedUser1Balance).to.eq(newBlockedUser1Balance-151750000n)
    })

    it("another",async function(){
        await expect(storeContract.getProductById(69)).to.be.reverted
        await expect(storeContract.connect(merchant1).deleteProduct(5)).to.be.reverted
        await storeContract.findIndexById(777)


        
        await storeContract.connect(owner).prematureUnblockingFunds(user1)
        const blockedUser1Funds = await storeContract.getBlockedBalance(user1)
        console.log("blockedUser1Funds:",blockedUser1Funds)
        expect(blockedUser1Funds).to.eq(0n)
    })
})