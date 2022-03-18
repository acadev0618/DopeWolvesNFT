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

    uint256 public commonRewardRate;
    uint256 public uncommonRewardRate;
    uint256 public rateRewardRate;
    uint256 public epicRewardRate;
    uint256 public LegendaryRewardRate;
    uint256 public amount;
    uint256 public balanceOfRewardToken;

    struct Staker {
        uint256[] tokenIds;
        mapping (uint256 => uint256) tokenIndex;
        uint256 commonTokenCnt;
        uint256 uncommonTokenCnt;
        uint256 rareTokenCnt;
        uint256 epicTokenCnt;
        uint256 legendaryTokenCnt;
    }
    mapping (address => Staker) public stakers;

    enum Rarity_Level {COMMON, UNUSUAL, RARE, EPIC, LEGENDARY}

    // for staking and unstaking
    uint constant COMMUNITY_WALLETS_PERSENT = 70; // 70% of the transaction fee
    uint constant TEAM_WALLETS_PERSENT = 30; // 30% of the transaction fee

    // default persent of wolf
    mapping(Rarity_Level => uint256) public rarityLevelRate;

    struct TokenRoyalty {
        address owner;
        Rarity_Level rarityLevel;
    }
    mapping(uint256 => TokenRoyalty) public tokenRoyalty;

    /// @notice event emitted when a user has staked a token
    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address owner, uint256 amount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsTokenUpdated(address indexed oldRewardsToken, address newRewardsToken );

    constructor(address _rewardsToken, address _stakingToken) public{
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC721Enumerable(_stakingToken);
        setDefaultTokenRoyalty();
    }

    /// @dev Getter functions for Staking contract
    /// @dev Get the tokens staked by a user
    function getStakedTokens(address _user) external view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function setRarityLevel(uint256 _tokenId, Rarity_Level level) public {
        TokenRoyalty storage token = tokenRoyalty[_tokenId];
        token.rarityLevel = level;
    }

    function setTokenRoyalty(Rarity_Level _rarity_level, uint256 persent) public {
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

    function setRewardContract(address _addr) external
    {
        address oldAddr = address(rewardsToken);
        rewardsToken = IERC20(_addr);
        emit RewardsTokenUpdated(oldAddr, _addr);
    }

    /// @notice Stake NFTs
    function stake(uint256 _tokenId) external
    {
        require(msg.sender == stakingToken.ownerOf(_tokenId), "DWNFTStaking.unstake: Sender must be the owner of NFT");
        _stake(msg.sender, _tokenId);
    }

    /// @notice Stake multiple NFTs.
    function stakeBatch(uint256[] memory _tokenIds) external
    {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (msg.sender == stakingToken.ownerOf(_tokenIds[i])){
            _stake(msg.sender, _tokenIds[i]);
            }
        }
    }

    /// @notice Stake all your NFTs.
    function stakeAll(address _owner) external
    {
        uint256 balance = stakingToken.balanceOf(_owner);
        for (uint i = 0; i < balance; i++) {
            _stake(_owner, stakingToken.tokenOfOwnerByIndex(_owner,i));
        }
    }

    /**
     * @dev All the staking goes through this function
    */
    function _stake(address _user, uint256 _tokenId) public {
        tokenRoyalty[_tokenId].owner = _user;
        Staker storage staker = stakers[_user];
        TokenRoyalty storage token = tokenRoyalty[_tokenId];

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
        // claimReward(msg.sender);
        _unstake(msg.sender, _tokenId);
        
    }

    /// @notice Stake multiple  NFTs
    function unstakeBatch(uint256[] memory tokenIds) external
    {
        // claimReward(msg.sender);
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenRoyalty[tokenIds[i]].owner == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }
    /**
     * @dev All the unstaking goes through this function
    */
    function _unstake(address _user, uint256 _tokenId) public {
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