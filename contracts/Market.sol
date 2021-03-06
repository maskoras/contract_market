pragma solidity ^0.4.4;

import "./Whitelist.sol"; 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}
 
/// @title Interface new rabbits address
contract PublicInterface { 
    function transferFrom(address _from, address _to, uint32 _tokenId) public returns (bool);
    function ownerOf(uint32 _tokenId) public view returns (address owner);
    function isUIntPublic() public view returns(bool);// check pause
}

contract Market  is Whitelist { 
           
    using SafeMath for uint256;
    
    event StopMarket(uint32 bunnyId);
    event StartMarket(uint32 bunnyId, uint money, uint timeStart, uint stepTimeSale);
    event BunnyBuy(uint32 bunnyId, uint money);  
    event Tournament(address who, uint bank, uint timeLeft, uint timeRange);
    event AddBank(uint bankMoney, uint countInvestor, address lastOwner, uint addTime, uint stepTime);
    
    bool public pause = false; 
    
    uint stepTimeBank = 50*60; 
    uint stepTimeSale = (stepTimeBank/10)+stepTimeBank;

  //  uint stepTimeBank = 1; 
  //  uint stepTimeSale = (stepTimeBank/10)+stepTimeBank;


    uint minPrice = 0.001 ether;
    uint reallyPrice = 0.001 ether;
    uint rangePrice = 2;

    uint minTimeBank = 300;
    uint coefficientTimeStep = 5;
 
    uint public commission = 5;
    uint public percentBank = 10;

    // how many times have the bank been increased
 
    uint added_to_the_bank = 0;

    uint marketCount = 0; 
    uint numberOfWins = 0;  
    uint getMoneyCount = 0;

    string public advertising = "Your advertisement here!";

     uint sec = 1;
    // how many last sales to take into account in the contract before the formation of the price
  //  uint8 middlelast = 20;
     
     
 
    // the last cost of a sold seal
    uint lastmoney = 0;   
    uint totalClosedBID = 0;

    // how many a bunny
    mapping (uint32 => uint) public bunnyCost;
    mapping (uint32 => uint) public timeCost;

    
    address public lastOwner;
    uint bankMoney;
    uint lastSaleTime;

    address public pubAddress;
    PublicInterface publicContract; 


    /**
    * For convenience in the client interface
     */
    function getProperty() public view 
    returns(
            uint tmp_stepTimeBank,
            uint tmp_stepTimeSale,
            uint tmp_minPrice,
            uint tmp_reallyPrice,
          //  uint tmp_rangePrice,
          //  uint tmp_commission,
          //  uint tmp_percentBank,
            uint tmp_added_to_the_bank,
            uint tmp_marketCount, 
            uint tmp_numberOfWins,
            uint tmp_getMoneyCount,
            uint tmp_lastmoney,   
            uint tmp_totalClosedBID,
            uint tmp_bankMoney,
            uint tmp_lastSaleTime
            )
            {
                tmp_stepTimeBank = stepTimeBank;
                tmp_stepTimeSale = stepTimeSale;
                tmp_minPrice = minPrice;
                tmp_reallyPrice = reallyPrice;
              //  tmp_rangePrice = rangePrice;
             //   tmp_commission = commission;
             //   tmp_percentBank = percentBank;
                tmp_added_to_the_bank = added_to_the_bank;
                tmp_marketCount = marketCount; 
                tmp_numberOfWins = numberOfWins;
                tmp_getMoneyCount = getMoneyCount;

                tmp_lastmoney = lastmoney;   
                tmp_totalClosedBID = totalClosedBID;
                tmp_bankMoney = bankMoney;
                tmp_lastSaleTime = lastSaleTime;
    }


    constructor() public {
        // 0xc7984712b3d0fac8e965dd17a995db5007fe08f2
       //  transferContract(0xca4455A4Fd80f43bD3efCDE2B84C1e069975e222);
        transferContract(0xc7984712B3d0FAC8e965DD17a995db5007fE08F2);
    }

    function setRangePrice(uint _rangePrice) public onlyWhitelisted {
        require(_rangePrice > 0);
        rangePrice = _rangePrice;
    }
    // minimum time step
    function setMinTimeBank(uint _minTimeBank) public onlyWhitelisted {
        require(_minTimeBank > 0);
        minTimeBank = _minTimeBank;
    }

    // time increment change rate
    function setCoefficientTimeStep(uint _coefficientTimeStep) public onlyWhitelisted {
        require(_coefficientTimeStep > 0);
        coefficientTimeStep = _coefficientTimeStep;
    }

 

    function setPercentCommission(uint _commission) public onlyWhitelisted {
        require(_commission > 0);
        commission = _commission;
    }

    function setPercentBank(uint _percentBank) public onlyWhitelisted {
        require(_percentBank > 0);
        percentBank = _percentBank; 
    }
    /**
    * @dev change min price a bunny
     */
    function setMinPrice(uint _minPrice) public onlyWhitelisted {
        require(_minPrice > (10**15));
        minPrice = _minPrice;
        
    }

    function setStepTime(uint _stepTimeBank) public onlyWhitelisted {
        require(_stepTimeBank > 0);
        stepTimeBank = _stepTimeBank;
        stepTimeSale = (stepTimeBank/10)+stepTimeBank;
    }
 
 
 
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _pubAddress  public address of the main contract
    */
    function transferContract(address _pubAddress) public onlyWhitelisted {
        require(_pubAddress != address(0)); 
        pubAddress = _pubAddress;
        publicContract = PublicInterface(_pubAddress);
    } 
 
    function setPause() public onlyWhitelisted {
        pause = !pause;
    }

    function isPauseSave() public  view returns(bool){
        return !pause;
    }

    /**
    * @dev get rabbit price
    */
    function currentPrice(uint32 _bunnyid) public view returns(uint) { 
        uint money = bunnyCost[_bunnyid];
        if (money > 0) {
            uint percOne = money.div(100);
            // commision
            uint commissionMoney = percOne.mul(commission);
            money = money.add(commissionMoney); 
            uint percBank = percOne.mul(percentBank);
            money = money.add(percBank); 
            return money;
        }
    } 

    /**
    * @dev We are selling rabbit for sale
    * @param _bunnyId - whose rabbit we exhibit 
    * @param _money - sale amount 
    */
  function startMarket(uint32 _bunnyId, uint _money) public returns (uint) {
        require(checkContract());
        require(isPauseSave());
        require(_money >= reallyPrice);
        require(publicContract.ownerOf(_bunnyId) == msg.sender);
        bunnyCost[_bunnyId] = _money;
        timeCost[_bunnyId] = block.timestamp;
        
        emit StartMarket(_bunnyId, currentPrice(_bunnyId), block.timestamp, stepTimeSale);
        return marketCount++;
    }

    /**
    * @dev remove from sale rabbit
    * @param _bunnyId - a rabbit that is removed from sale 
    */
    function stopMarket(uint32 _bunnyId) public returns(uint) {
        require(checkContract());
        require(isPauseSave());
        require(publicContract.ownerOf(_bunnyId) == msg.sender);
        bunnyCost[_bunnyId] = 0;
        emit StopMarket(_bunnyId);
        return marketCount--;
    }
 
 
    function changeReallyPrice() internal {
        if (added_to_the_bank > 0 && rangePrice > 0) {
            uint tmp = added_to_the_bank.div(rangePrice);
            reallyPrice = tmp * (10**15)+reallyPrice; 


            uint tmpTime = added_to_the_bank.div(coefficientTimeStep);
            if (tmpTime <= minTimeBank) {
                stepTimeBank = minTimeBank;
            } else {
                stepTimeBank = tmpTime;
            }
        } 
    }
 
     


    function timeBunny(uint32 _bunnyId) public view returns(bool can, uint timeleft) {
        uint _tmp = timeCost[_bunnyId].add(stepTimeSale);
        if (timeCost[_bunnyId] > 0 && block.timestamp >= _tmp) {
            can = true;
            timeleft = 0;
        } else { 
            can = false; 
            _tmp = block.timestamp.sub(_tmp);
            if (_tmp > 0) {
                timeleft = _tmp;
            } else {
                timeleft = 0;
            }
        } 
    }

    function transferFromBunny(uint32 _bunnyId) public {
        require(checkContract());
        publicContract.transferFrom(publicContract.ownerOf(_bunnyId), msg.sender, _bunnyId); 
    }


// https://rinkeby.etherscan.io/address/0xc7984712b3d0fac8e965dd17a995db5007fe08f2#writeContract
    /**
    * @dev Acquisition of a rabbit from another user
    * @param _bunnyId  Bunny
     */
    function buyBunny(uint32 _bunnyId) public payable {
        require(isPauseSave());
        require(checkContract());
        require(publicContract.ownerOf(_bunnyId) != msg.sender);
        lastmoney = currentPrice(_bunnyId);
        require(msg.value >= lastmoney && 0 != lastmoney);

        bool can;
        (can,) = timeBunny(_bunnyId);
        require(can); 
        // stop trading on the current rabbit
        totalClosedBID++;
        // Sending money to the old user 
        // is sent to the new owner of the bought rabbit
        publicContract.transferFrom(publicContract.ownerOf(_bunnyId), msg.sender, _bunnyId); 

        stopMarket(_bunnyId); 
        checkTimeWin();
        
        sendMoney(publicContract.ownerOf(_bunnyId), msg.value);
        
        changeReallyPrice();

        lastOwner = msg.sender; 
        lastSaleTime = block.timestamp; 

        emit BunnyBuy(_bunnyId, lastmoney);
    } 
     

    function checkTimeWin() internal {
        if (lastSaleTime + stepTimeBank < block.timestamp) {
            win(); 
        }
        lastSaleTime = block.timestamp;
    }
    function win() internal {
        // ####### WIN ##############
        // send money
        if (address(this).balance > 0 && address(this).balance >= bankMoney && lastOwner != address(0)) { 
            advertising = "";
            added_to_the_bank = 0;
            reallyPrice = minPrice;
            lastOwner.transfer(bankMoney);
            numberOfWins = numberOfWins.add(1); 
            emit Tournament (lastOwner, bankMoney, lastSaleTime, block.timestamp);
            bankMoney = 0;
        }
    }    
    
        /**
    * @dev add money of bank
    */
    function addBank(uint _money) internal { 
        bankMoney = bankMoney.add(_money);
        added_to_the_bank = added_to_the_bank.add(1);

        emit AddBank(bankMoney, added_to_the_bank, lastOwner, block.timestamp, stepTimeBank);

    }  
    
    /**
    * @param _to to whom money is sent
    * @param _money the amount of money is being distributed at the moment
     */
    function sendMoney(address _to, uint256 _money) internal { 
        if (_money > 0) { 
            uint procentOne = (_money/100); 
            _to.transfer(procentOne * (100-(commission+percentBank)));
            addBank(procentOne*percentBank);
            ownerMoney.transfer(procentOne*commission);  
        }
    }
 
    function ownerOf(uint32 _bunnyId) public  view returns(address)  {
        return publicContract.ownerOf(_bunnyId);
    } 
    
    /**
    * Check
     */
    function checkContract() public view returns(bool) {
        return publicContract.isUIntPublic(); 
    }

    function buyAdvert(string _text)  public payable { 
        require(msg.value > (reallyPrice*2));
        require(checkContract());
        advertising = _text;
        addBank(msg.value); 
    }
 
    /**
    * Only if the user has violated the advertising rules
     */
    function noAdvert() public onlyWhitelisted {
        advertising = "";
    } 
 
    /**
    * Only unforeseen situations
     */
    function getMoney(uint _value) public onlyOwner {
        require(address(this).balance >= _value); 
        ownerMoney.transfer(_value);
        // for public, no scam
        getMoneyCount = getMoneyCount.add(_value);
    }
}
