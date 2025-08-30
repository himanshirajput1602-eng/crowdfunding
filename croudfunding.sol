// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CrowdfundingPlatform {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        bool isActive;
        bool goalReached;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => address[]) public contributors;
    
    uint256 public campaignCounter;
    uint256 public platformFee = 25; // 2.5% platform fee
    address public platformOwner;

    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 goalAmount, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function");
        _;
    }

    modifier validCampaign(uint256 _campaignId) {
        require(_campaignId < campaignCounter, "Campaign does not exist");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
        campaignCounter = 0;
    }

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationInDays
    ) external {
        require(_goalAmount > 0, "Goal amount must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");

        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaigns[campaignCounter] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            raisedAmount: 0,
            deadline: deadline,
            isActive: true,
            goalReached: false
        });

        emit CampaignCreated(campaignCounter, msg.sender, _title, _goalAmount, deadline);
        campaignCounter++;
    }

    function contribute(uint256 _campaignId) external payable validCampaign(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isActive, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than 0");

        if (contributions[_campaignId][msg.sender] == 0) {
            contributors[_campaignId].push(msg.sender);
        }

        contributions[_campaignId][msg.sender] += msg.value;
        campaign.raisedAmount += msg.value;

        if (campaign.raisedAmount >= campaign.goalAmount) {
            campaign.goalReached = true;
        }

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _campaignId) external validCampaign(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only campaign creator can withdraw funds");
        require(campaign.goalReached || block.timestamp >= campaign.deadline, "Campaign goal not reached or still active");
        require(campaign.raisedAmount > 0, "No funds to withdraw");

        uint256 amount = campaign.raisedAmount;
        uint256 fee = (amount * platformFee) / 1000;
        uint256 creatorAmount = amount - fee;

        campaign.raisedAmount = 0;
        campaign.isActive = false;

        payable(campaign.creator).transfer(creatorAmount);
        payable(platformOwner).transfer(fee);

        emit FundsWithdrawn(_campaignId, campaign.creator, creatorAmount);
    }

    function requestRefund(uint256 _campaignId) external validCampaign(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.goalReached, "Campaign goal was reached");
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(contributions[_campaignId][msg.sender] > 0, "No contribution found");

        uint256 refundAmount = contributions[_campaignId][msg.sender];
        contributions[_campaignId][msg.sender] = 0;
        campaign.raisedAmount -= refundAmount;

        payable(msg.sender).transfer(refundAmount);

        emit RefundIssued(_campaignId, msg.sender, refundAmount);
    }

    function getCampaignDetails(uint256 _campaignId) external view validCampaign(_campaignId) returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goalAmount,
        uint256 raisedAmount,
        uint256 deadline,
        bool isActive,
        bool goalReached
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.isActive,
            campaign.goalReached
        );
    }
}