// Get funds from users
// Withdraw funds
// set a minimum value in usd

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            PriceConverter.getConversionRate(msg.value, s_priceFeed) >=
                MINIMUM_USD,
            // getConversionRate(msg.value, priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        // require(msg.value >= MINIMUM_USD, "Didn't send enough");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner {
        for (
            uint256 founderIndex;
            founderIndex < s_funders.length;
            founderIndex++
        ) {
            address funder = s_funders[founderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // actually withdraw the amount
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Send Faild!");
    }

    modifier onlyOwner() {
        // require(msg.sender==i_owner,"Only Owner can call");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
