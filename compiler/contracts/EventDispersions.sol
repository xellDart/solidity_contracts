// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity >=0.6.2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.2;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/payment/escrow/Escrow.sol

pragma solidity >=0.6.2;

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    mapping(address => uint256) private _deposits;

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public virtual payable onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];
        _deposits[payee] = 0;
        payee.sendValue(payment);
    }
}

// File: States/Stages.sol

pragma solidity >=0.6.2;

contract Stage is Ownable {
    enum Stages {CREATION, SIGN, RUNNING, FINISH}

    Stages public stage = Stages.CREATION;

    modifier atStage(Stages _stage) {
        require(stage == _stage, "Function cannot be called at this time.");
        _;
    }

    function setStage(Stages _stage) internal {
        stage = _stage;
    }

    function destruct() internal {
        selfdestruct(payable(owner()));
    }
}

// File: Member.sol

pragma solidity >=0.6.2;

contract Members is Ownable, Stage {
    address[] private members_;

    mapping(address => Member) private relations_;
    struct Member {
        uint256 percent_;
        bool signed_;
        bool exist_;
    }

    //event addressSigned(address signed);

    function registerMember(address _member, uint256 _percent)
        public
        onlyOwner
        atStage(Stages.CREATION)
    {
        require(!relations_[_member].exist_, "Member already exist.");
        members_.push(_member);
        relations_[_member].percent_ = _percent;
        relations_[_member].signed_ = false;
        relations_[_member].exist_ = true;
    }

    function signMember(address _member) internal {
        setStage(Stages.SIGN);
        require(relations_[_member].exist_, "Invalid verification");
        require(!relations_[_member].signed_, "Already signed");
        relations_[_member].signed_ = true;
        //emit addressSigned(_member);
    }

    function getMember(address _member) public view returns (uint256, bool) {
        Member memory p = relations_[_member];
        return (p.percent_, p.exist_);
    }

    function getMembers() public view onlyOwner returns (address[] memory) {
        return members_;
    }

    function allSigned() internal view returns (bool) {
        bool start = false;
        for (uint256 i = 0; i < members_.length; i++) {
            start = relations_[members_[i]].signed_;
        }
        return start;
    }
}

// File: Utils/Info.sol

pragma solidity >=0.6.2;

contract Info {
    struct PayInfo {
        uint256 total_;
        address investor_;
    }

    PayInfo private info;

    function setTotal(address _investor) internal {
        info.total_ = address(this).balance;
        info.investor_= _investor;
    }

    function getInvestor() public view returns (address) {
        return info.investor_;
    }

    function getTotal() internal view returns (uint256) {
        return info.total_;
    }

    modifier withFunds() {
        require(info.total_ > 0, "Contract balance is 0");
        _;
    }
}

// File: Payment/EventDispersion.sol

pragma solidity >=0.6.2;

contract EventDispersion is Ownable, Stage, Members, Info {
    struct Event {
        bytes description_;
        bool executed_;
    }

    function typeContract() public pure returns (bytes memory) {
        return "event_contract";
    }

    Event private event_;
    Escrow private _escrow;

    constructor() public {
        _escrow = new Escrow();
    }

    function createEvent(bytes memory _description)
        public
        onlyOwner
        atStage(Stages.CREATION)
    {
        event_.description_ = _description;
    }

    function getEvent() public view returns (bytes memory) {
        return event_.description_;
    }

    receive() external payable {
        setTotal(msg.sender);
    }

    function executeEvent() public onlyOwner atStage(Stages.RUNNING) {
        event_.executed_ = true;
        dispersion();
    }

    function dispersion() private {
        require(event_.executed_, "Event not executed");
        address[] memory members_ = getMembers();
        for (uint256 i = 0; i < members_.length; i++) {
            (uint256 percent, ) = getMember(members_[i]);
            pay(members_[i], (getTotal() * percent) / 100);
        }
        setStage(Stages.FINISH);
    }

    function pay(address _to, uint256 _amount) private {
        _escrow.deposit{value: _amount}(_to);
        _escrow.withdraw(payable(_to));
    }

    function refund() public onlyOwner atStage(Stages.CREATION) {
        _escrow.deposit{value: getTotal()}(getInvestor());
        _escrow.withdraw(payable(getInvestor()));
    }

    function sign(address _member) public withFunds {
        signMember(_member);
        bool start = allSigned();
        if (start) setStage(Stages.RUNNING);
    }
}

// File: Trato.sol

pragma solidity >=0.6.2;

contract Trato is EventDispersion {
    bytes private hash_;

    function setHash(bytes memory _hash) public onlyOwner {
        hash_ = _hash;
    }

    function getHash() public view returns (bytes memory) {
        return hash_;
    }
}
