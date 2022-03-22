//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "hardhat/console.sol";

/**
 * @title DopeWolves Staking
 * @dev Stake NFTs, earn tokens on the DW platform
 * @author Aleksandar Todorovic
 */
 contract DWNFTStaking {
    using SafeMath for uint256;

    IERC20 public rewardsToken;
    IERC721Enumerable public stakingToken;

    uint256 allCommonTokenCnt;
    uint256 allUncommonTokenCnt;
    uint256 allRareTokenCnt;
    uint256 allEpicTokenCnt;
    uint256 allLegendaryTokenCnt;

    uint256 private balanceOfRewardToken;
    bool isHuntingSeason;

    struct Staker {
        uint256[] tokenIds;
        mapping (uint256 => uint256) tokenIndex;
        uint256 commonTokenCnt;
        uint256 uncommonTokenCnt;
        uint256 rareTokenCnt;
        uint256 epicTokenCnt;
        uint256 legendaryTokenCnt;
        bool rewarded;
    }
    mapping (address => Staker) public stakers;

    enum Rarity_Level {COMMON, UNUSUAL, RARE, EPIC, LEGENDARY}
    // for staking and unstaking
    uint constant private COMMUNITY_WALLETS_PERSENT = 70; // 70% of the transaction fee
    uint constant private TEAM_WALLETS_PERSENT = 30; // 30% of the transaction fee

    // default persent of wolf
    mapping(Rarity_Level => uint256) public rarityLevelRate;

    struct TokenRoyalty {
        address owner;
        Rarity_Level rarityLevel;
        bool isStaking;
    }
    mapping(uint256 => TokenRoyalty) public tokenRoyalty;

    /// @notice event emitted when a user has staked a token
    event Staked(address owner, uint256 amount);
    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address owner, uint256 amount);
    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _rewardsToken, address _stakingToken){
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC721Enumerable(_stakingToken);
        setDefaultTokenRoyalty();
        balanceOfRewardToken = getBalanceRewardToken().mul(70).div(100);
    }

    /// @dev Getter functions for Staking contract
    /// @dev Get the tokens staked by a user
    function getStakedTokens(address _user) public view
        returns (uint256[] memory)
    {
        return stakers[_user].tokenIds;
    }

    function setRarityLevel(uint256 _tokenId, Rarity_Level level) external {
        TokenRoyalty storage token = tokenRoyalty[_tokenId];
        token.rarityLevel = level;
    }

    function setTokenRoyalty(Rarity_Level _rarity_level, uint256 persent) external {
        rarityLevelRate[_rarity_level] = persent;
    }

    function setDefaultTokenRoyalty() internal {
        rarityLevelRate[Rarity_Level.COMMON] = 20; // commoun wolves
        rarityLevelRate[Rarity_Level.UNUSUAL] = 20; // Unusual wolves
        rarityLevelRate[Rarity_Level.RARE] = 20; // Rare wolves
        rarityLevelRate[Rarity_Level.EPIC] = 20; // Epic wolves
        rarityLevelRate[Rarity_Level.LEGENDARY] = 10; // Legendary wolves
    }

    function getBalanceRewardToken() public view returns (uint256){
        return rewardsToken.balanceOf(msg.sender);
    }

    function startHuntingSeason() public {
        isHuntingSeason = true;
    }

    function timeOutHuntingSeason() public {
        balanceOfRewardToken = getBalanceRewardToken().mul(70).div(100);
        // reward all users
        uint256 balance = stakingToken.totalSupply();
        for (uint i = 0; i < balance; i++) {
            TokenRoyalty storage token = tokenRoyalty[i];
            if(token.isStaking && ! stakers[token.owner].rewarded){
                claimReward(token.owner);
                console.log("claimReward : ", token.owner);
            }
        }
        // all unstaking
        for (uint i = 0; i < balance; i++) {
            TokenRoyalty storage token = tokenRoyalty[i];
            if(token.isStaking){
                console.log("unstaked ", token.owner, " tokenid:  ", i);
                _unstake(token.owner, i);
            }
        }
        // set hunt season false
        isHuntingSeason = false;
    }

    function calculateRewardAmount(address _user) public view returns (uint256) {
        uint256 commonRewardRate;
        uint256 uncommonRewardRate;
        uint256 rateRewardRate;
        uint256 epicRewardRate;
        uint256 LegendaryRewardRate;

        require(balanceOfRewardToken > 0, " low balance of rewards token");
        if (allCommonTokenCnt > 0)
            commonRewardRate = (balanceOfRewardToken.mul(rarityLevelRate[Rarity_Level.COMMON]).div(100)).div(allCommonTokenCnt);
        if (allUncommonTokenCnt > 0)
            uncommonRewardRate = (balanceOfRewardToken.mul(rarityLevelRate[Rarity_Level.UNUSUAL]).div(100)).div(allUncommonTokenCnt);
        if (allRareTokenCnt > 0)
            rateRewardRate = (balanceOfRewardToken.mul(rarityLevelRate[Rarity_Level.RARE]).div(100)).div(allRareTokenCnt);
        if (allRareTokenCnt > 0)
            epicRewardRate = (balanceOfRewardToken.mul(rarityLevelRate[Rarity_Level.EPIC]).div(100)).div(allEpicTokenCnt);
        if (allRareTokenCnt > 0)
            LegendaryRewardRate = (balanceOfRewardToken.mul(rarityLevelRate[Rarity_Level.LEGENDARY]).div(100)).div(allLegendaryTokenCnt);
        
        Staker storage staker = stakers[_user];

        uint256 amount = (staker.commonTokenCnt.mul(commonRewardRate)) +
                (staker.uncommonTokenCnt.mul(uncommonRewardRate)) +
                (staker.rareTokenCnt.mul(rateRewardRate)) +
                (staker.epicTokenCnt.mul(epicRewardRate)) +
                (staker.legendaryTokenCnt.mul(LegendaryRewardRate));

        console.log("Reward amount for Adress: ", amount, _user);
        return amount;
    }

    /// @notice Lets a user with rewards owing to claim tokens
    function claimReward(address _user) private {
        uint256 amount;
        amount = calculateRewardAmount(_user);
        // rewardsToken.transferFrom(msg.sender, _user, amount);
        Staker storage staker = stakers[_user];
        staker.rewarded = true;
        emit RewardPaid(_user, amount);
    }

    /// @notice Stake NFTs
    function stake(uint256 _tokenId) external
    {
        require(isHuntingSeason, "DWNFTStaking.stake:now it's not hunt season, so can't stake dope wolves");
        require(msg.sender == stakingToken.ownerOf(_tokenId), "DWNFTStaking.stake: Sender must be the owner of NFT");
        _stake(msg.sender, _tokenId);
    }

    /// @notice Stake multiple NFTs.
    function stakeBatch(uint256[] memory _tokenIds) external
    {
        require(isHuntingSeason, "DWNFTStaking.stake:now it's not hunt season, so can't stake dope wolves");
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (msg.sender == stakingToken.ownerOf(_tokenIds[i])){
            _stake(msg.sender, _tokenIds[i]);
            }
        }
    }

    /// @notice Stake all your NFTs.
    // function stakeAll(address _owner) external
    // {
    //     uint256 balance = stakingToken.balanceOf(_owner);
    //     for (uint i = 0; i < balance; i++) {
    //         console.log("tokenid : ", stakingToken.tokenOfOwnerByIndex(_owner,i));
    //         _stake(_owner, stakingToken.tokenOfOwnerByIndex(_owner,i));
    //     }
    // }

    /**
     * @dev All the staking goes through this function
    */
    function _stake(address _user, uint256 _tokenId) internal {
        tokenRoyalty[_tokenId].owner = _user;
        Staker storage staker = stakers[_user];
        TokenRoyalty storage token = tokenRoyalty[_tokenId];
        token.owner = _user;
        token.isStaking = true;

        if (token.rarityLevel == Rarity_Level.COMMON) {
            staker.commonTokenCnt++;
            allCommonTokenCnt++;
        }
        if (token.rarityLevel == Rarity_Level.UNUSUAL) {
            staker.uncommonTokenCnt++;
            allUncommonTokenCnt++;
        }
        if (token.rarityLevel == Rarity_Level.RARE) {
            staker.rareTokenCnt++;
            allRareTokenCnt++;
        }
        if (token.rarityLevel == Rarity_Level.EPIC) {
            staker.epicTokenCnt++;
            allEpicTokenCnt++;
        }
        if (token.rarityLevel == Rarity_Level.LEGENDARY) {
            staker.legendaryTokenCnt++;
            allLegendaryTokenCnt++;
        }

        staker.tokenIds.push(_tokenId);
        staker.tokenIndex[staker.tokenIds.length - 1];

        // _burn(_tokenId);
        stakingToken.transferFrom(_user, address(this), _tokenId);
        emit Staked(_user, _tokenId);
    }

    /// @notice Unstake NFTs.
    function unstake(uint256 _tokenId) external
    {
        require(msg.sender == tokenRoyalty[_tokenId].owner, "DWNFTStaking.unstake: Sender must have staked tokenID");
        _unstake(msg.sender, _tokenId);
    }

    /// @notice Stake multiple  NFTs
    function unstakeBatch(uint256[] memory tokenIds) external
    {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenRoyalty[tokenIds[i]].owner == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }
    /**
     * @dev All the unstaking goes through this function
    */
    function _unstake(address _user, uint256 _tokenId) private {
        Staker storage staker = stakers[_user];
        TokenRoyalty storage token = tokenRoyalty[_tokenId];

        if (token.rarityLevel == Rarity_Level.COMMON) {
            staker.commonTokenCnt--;
            allCommonTokenCnt--;
        }
        if (token.rarityLevel == Rarity_Level.UNUSUAL) {
            staker.uncommonTokenCnt--;
            allUncommonTokenCnt--;
        }
        if (token.rarityLevel == Rarity_Level.RARE) {
            staker.rareTokenCnt--;
            allRareTokenCnt--;
        }
        if (token.rarityLevel == Rarity_Level.EPIC) {
            staker.epicTokenCnt--;
            allEpicTokenCnt--;
        }
        if (token.rarityLevel == Rarity_Level.LEGENDARY) {
            staker.legendaryTokenCnt--;
            allLegendaryTokenCnt--;
        }

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];
        staker.tokenIds[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[_tokenId];
        }

        if (staker.tokenIds.length == 0) {
            delete stakers[_user];
        }
        delete tokenRoyalty[_tokenId];
        // _safeMint(_user, _tokenId);
        stakingToken.transferFrom(address(this), _user, _tokenId);
        emit Unstaked(_user, _tokenId);
    }
 }