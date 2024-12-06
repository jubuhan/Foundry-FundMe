// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe{
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD=5e18; 
    address[] private s_funders;
    mapping (address funder => uint256 amountFunded) private s_addresstoAmountFunded;
    
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    constructor(address priceFeed) {
       i_owner=msg.sender;
       s_priceFeed=AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
       
       require( msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,"didnt send enough");
      
       s_addresstoAmountFunded[msg.sender]+=msg.value; 
        s_funders.push(msg.sender);


    }
   function getVersion() public view returns (uint256) {
     
        return s_priceFeed.version();
   }

   function cheaperWithdraw() public onlyOwner{
     uint256 fundersLength= s_funders.length;
      for(uint256 funderIndex=0;funderIndex<fundersLength;funderIndex++){
            address funder=s_funders[funderIndex];
            s_addresstoAmountFunded[funder]=0;
        }
        s_funders=new address[](0);
        //call
        (bool callSuccess,)=payable (msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "call failed");

   }

    function witdraw() public onlyOwner{
        
        for(uint256 funderIndex=0;funderIndex<s_funders.length;funderIndex++){
            address funder=s_funders[funderIndex];
            s_addresstoAmountFunded[funder]=0;
        }
        s_funders=new address[](0);
        //call
        (bool callSuccess,)=payable (msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "call failed");


    }
    modifier onlyOwner(){
        //require(msg.sender==i_owner, "sender is not owner");
        if(msg.sender!=i_owner){ revert FundMe__NotOwner();}
        _;
    }


    receive() external payable {
        fund();
     }
     fallback() external payable {
        fund();
      }

  function getAddressToAmountFunded(address fundingAddress)external view returns(uint256){
    return s_addresstoAmountFunded[fundingAddress];
  }

  function getFunder(uint256 index) external view returns(address){
    return s_funders[index];
  }

  function getOwner()external view returns(address){
    return i_owner;
  }

}  