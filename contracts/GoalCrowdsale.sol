pragma solidity ^0.4.23;

import './common/math/SafeMath.sol';
import "./sale/FinalizableCrowdsale.sol";
import "./sale/RefundVault.sol";

contract GoalCrowdsale is FinalizableCrowdsale {
    // =================================================================================================================
    //                                      Constants
    // =================================================================================================================
    // Max amount of known addresses of which will get SRN by 'Grant' method.
    //
    // grantees addresses will be SirinLabs wallets addresses.
    // these wallets will contain SRN tokens that will be used for 2 purposes only -
    // 1. SRN tokens against raised fiat money
    // 2. SRN tokens for presale bonus.
    // we set the value to 10 (and not to 2) because we want to allow some flexibility for cases like fiat money that is raised close to the crowdsale.
    // we limit the value to 10 (and not larger) to limit the run time of the function that process the grantees array.
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    /**
     * @dev Throws if called not during the crowdsale time frame
     */
    modifier onlyWhileSale() {
        require(isActive());
        _;
    }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // Funds collected outside the crowdsale in wei
    uint256 public fiatRaisedConvertedToWei;

    //Grantees - used for non-ether and presale bonus token generation
    address[] public presaleGranteesMapKeys;
    mapping(address => uint256) public presaleGranteesMap;  //address=>wei token amount

    // The refund vault
    RefundVault public refundVault;

    // =================================================================================================================
    //                                      Events
    // =================================================================================================================
    event GrantAdded(address indexed _grantee, uint256 _amount);

    event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);

    event GrantDeleted(address indexed _grantee, uint256 _hadAmount);

    event FiatRaisedUpdated(address indexed _address, uint256 _fiatRaised);

    event TokenPurchaseWithGuarantee(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // =================================================================================================================
    //                                      Constructors
    // =================================================================================================================

    constructor(uint256 _startTime,
                uint256 _endTime,
                address _mainWallet,
                uint256 _rate,
                MyGoalToken _goalSmartToken,
                RefundVault _refundVault)
    public Crowdsale(_startTime, _endTime, _rate, _mainWallet, _goalSmartToken) {
        require(_refundVault != address(0));

        token = _goalSmartToken;
        refundVault = _refundVault;
    }

    // =================================================================================================================
    //                                      Impl Crowdsale
    // =================================================================================================================

    // @return the rate in GOAL per 1 ETH according to the time of the tx and the GOAL pricing program.
    function setRate(uint256 _rate) internal onlyOwner onlyWhileSale returns (uint256) {
        rate = _rate;
        return getRate();
    }

    // =================================================================================================================
    //                                      Impl FinalizableCrowdsale
    // =================================================================================================================

    //@Override
    function finalization() internal onlyOwner {
        super.finalization();

        // granting bonuses for the pre crowdsale grantees:
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            //todo: replace issue with transfer
//            token.issue(presaleGranteesMapKeys[i], presaleGranteesMap[presaleGranteesMapKeys[i]]);
        }

        // Re-enable transfers after the token sale.
        //todo: replace with pause?
//        token.disableTransfers(false);

        // Re-enable destroy function after the token sale.
        //todo: remove?
//        token.setDestroyEnabled(true);

        // Enable ETH refunds and token claim.
        refundVault.enableRefunds();

        // transfer token ownership to crowdsale owner
        token.transferOwnership(owner);

        // transfer refundVault ownership to crowdsale owner
        refundVault.transferOwnership(owner);
    }

    // =================================================================================================================
    //                                      Public Methods
    // =================================================================================================================
    // @return the total funds collected in wei(ETH and none ETH).
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

    // @return true if the crowdsale is active, hence users can buy tokens
    function isActive() public view returns (bool) {
        return now >= startTime && now < endTime;
    }

    // =================================================================================================================
    //                                      External Methods
    // =================================================================================================================
    // @dev Adds/Updates address and token allocation for token grants.
    // Granted tokens are allocated to non-ether, presale, buyers.
    // @param _grantee address The address of the token grantee.
    // @param _value uint256 The value of the grant in wei token.
    function addUpdateGrantee(address _grantee, uint256 _value) external onlyOwner onlyWhileSale {
        require(_grantee != address(0));
        //todo: use min value?
        require(_value > 0);

        // Adding new key if not present:
        if (presaleGranteesMap[_grantee] == 0) {
            require(presaleGranteesMapKeys.length < MAX_TOKEN_GRANTEES);
            presaleGranteesMapKeys.push(_grantee);
            emit GrantAdded(_grantee, _value);
        } else {
            emit GrantUpdated(_grantee, presaleGranteesMap[_grantee], _value);
        }

        presaleGranteesMap[_grantee] = _value;
    }

    // @dev deletes entries from the grants list.
    // @param _grantee address The address of the token grantee.
    function deleteGrantee(address _grantee) external onlyOwner onlyWhileSale {
        require(_grantee != address(0));
        require(presaleGranteesMap[_grantee] != 0);

        //delete from the map:
        delete presaleGranteesMap[_grantee];

        //delete from the array (keys):
        uint256 index;
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            if (presaleGranteesMapKeys[i] == _grantee) {
                index = i;
                break;
            }
        }
        presaleGranteesMapKeys[index] = presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        delete presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        presaleGranteesMapKeys.length--;

        emit GrantDeleted(_grantee, presaleGranteesMap[_grantee]);
    }

    // @dev Set funds collected outside the crowdsale in wei.
    //  note: we not to use accumulator to allow flexibility in case of humane mistakes.
    // funds are converted to wei using the market conversion rate of USD\ETH on the day on the purchase.
    // @param _fiatRaisedConvertedToWei number of none eth raised.
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        emit FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }

    /// @dev Accepts new ownership on behalf of the SirinCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the SirinSmartToken contract.
    function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }

    /// @dev Accepts new ownership on behalf of the SirinCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the refundVault contract.
    function claimRefundVaultOwnership() external onlyOwner {
        refundVault.claimOwnership();
    }

    // @dev Buy tokes with guarantee
    function buyTokensWithGuarantee() public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // update state
        weiRaised = weiRaised.add(weiAmount);

        //todo: replace with transfer
//        token.issue(address(refundVault), tokens);

        refundVault.deposit.value(msg.value)(msg.sender, tokens);

        emit TokenPurchaseWithGuarantee(msg.sender, address(refundVault), weiAmount, tokens);
    }
}
