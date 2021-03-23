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
    constructor() public {
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
// File: Utils/Info.sol

pragma solidity >=0.6.2;

contract Info {
    struct PayInfo {
        uint256 total_;
        address investor_;
        uint8 position_;
    }

    PayInfo private info;

    function setTotal(address _investor) internal {
        info.total_ = address(this).balance;
        info.investor_ = _investor;
    }

    function getInvestor() public view returns (address) {
        return info.investor_;
    }

    function addPosition() internal {
        info.position_ = info.position_ + 1;
    }

    function getPosition() internal view returns (uint8) {
        return info.position_;
    }

    function getTotal() internal view returns (uint256) {
        return info.total_;
    }

    modifier withFunds() {
        require(info.total_ > 0, "Contract balance is 0");
        _;
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
    using SafeMath for uint256;

    address[] private members_;

    mapping(address => Member) private relations_;
    struct Member {
        uint256 percent_;
        bool signed_;
        bool exist_;
    }

    event addressSigned(address signed);

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
        emit addressSigned(_member);
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

// File: Time/Time.sol

pragma solidity >=0.6.2;

contract Time is Ownable, Stage {
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    struct Date {
        bool running_;
        bytes32 unitEnd_;
        bytes32 unitDispersion_;
        uint256[] percents_;
        uint8 duration_;
        uint8 every_;
        _DateTime start_;
        _DateTime end_;
        _DateTime nextPayment_;
    }

    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    Date private current;

    function exec() internal atStage(Stages.RUNNING) {
        require(current.duration_ != 0, "End time not set");
        require(current.every_ != 0, "Set lapseds first");
        _DateTime memory time = parseTimestamp(block.timestamp);
        current.start_ = time;
        current.nextPayment_ = parseTime(
            time,
            current.every_,
            current.unitDispersion_
        );
        current.end_ = parseTime(time, current.duration_, current.unitEnd_);
        current.running_ = true;
    }

    function setEnd(uint8 _duration, bytes32 _unit)
        public
        onlyOwner
        atStage(Stages.CREATION)
    {
        require(
            _unit == "month" || _unit == "year" || _unit == "day",
            "Invalid time unit"
        );
        current.duration_ = _duration;
        current.unitEnd_ = _unit;
    }

    function setLapseds(
        uint256[] memory _percents,
        uint8 _every,
        bytes32 _unit
    ) public onlyOwner atStage(Stages.CREATION) {
        uint256 total = 0;
        for (uint256 i; i < _percents.length; i++) {
            total += (_percents[i] / 1e2);
        }
        require(total >= 99, "Invalid percents");
        current.unitDispersion_ = _unit;
        current.percents_ = _percents;
        current.every_ = _every;
    }

    function getStart()
        public
        view
        atStage(Stages.RUNNING)
        returns (
            uint16,
            uint8,
            uint8
        )
    {
        return (current.start_.year, current.start_.month, current.start_.day);
    }

    function getEnd()
        public
        view
        atStage(Stages.RUNNING)
        returns (
            uint16,
            uint8,
            uint8
        )
    {
        return (current.end_.year, current.end_.month, current.end_.day);
    }

    function getNextPayment()
        public
        view
        atStage(Stages.RUNNING)
        returns (
            uint16,
            uint8,
            uint8
        )
    {
        return (
            current.nextPayment_.year,
            current.nextPayment_.month,
            current.nextPayment_.day
        );
    }

    function setNextPayment() internal {
        require(current.every_ != 0, "Set lapseds first");
        current.nextPayment_ = parseTime(
            current.nextPayment_,
            current.every_,
            current.unitDispersion_
        );
    }

    function getTimePercents() internal view returns (uint256[] memory) {
        return current.percents_;
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (_DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
    }

    function getYear(uint256 timestamp) private pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) private pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) private pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) private pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        uint256 temp = year -= 1;
        return temp / 4 - temp / 100 + temp / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        private
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTime(
        _DateTime memory time,
        uint8 duration,
        bytes32 unit
    ) private pure returns (_DateTime memory dt) {
        dt = time;
        if (unit == "day") {
            uint8 daysMonth_ = getDaysInMonth(time.month, time.year);
            uint8 totalDays = time.day + duration;
            if (totalDays > daysMonth_) {
                dt.month = time.month + 1;
                dt.day = totalDays - daysMonth_;
            } else dt.day = time.day + duration;
        }
        if (unit == "month") {
            uint8 totalMonth = time.month + duration;
            if (totalMonth > 12) {
                dt.year = time.year + 1;
                dt.month = totalMonth - 12;
            } else dt.month = time.month + duration;
        }
        if (unit == "year") dt.year = time.year + duration;
    }

    modifier timeReady() {
        require(current.duration_ != 0, "Time not set");
        require(current.every_ != 0, "Time not set");
        _;
    }

    modifier payDay() {
        _DateTime memory time = parseTimestamp(block.timestamp);
        require(time.day == current.nextPayment_.day, "Invalid day of payment");
        require(
            time.month == current.nextPayment_.month,
            "Invalid month of payment"
        );
        require(
            time.year == current.nextPayment_.year,
            "Invalid year of payment"
        );
        _;
    }
}

// File: Payment/TimeDispersions.sol

pragma solidity >=0.6.2;

contract TimeDispersions is Stage, Time, Info, Members {
    Escrow private _escrow;
    address private _clock;

    constructor() public {
        _escrow = new Escrow();
    }

    receive() external payable {
        setTotal(msg.sender);
    }

    function typeContract() public pure returns (bytes memory) {
        return "time_contract";
    }

    function setTratoClock(address clock) internal {
        _clock = clock;
    }

    function dispersions() public atStage(Stages.RUNNING) payDay {
        require(msg.sender == _clock, "Only trato delayed service");
        uint256[] memory percents = getTimePercents();
        uint8 current = getPosition();
        if (current == percents.length) setStage(Stages.FINISH);
        else if (current < percents.length) {
            setMembers(((percents[current] / 1e2) * getTotal()) / 100);
            addPosition();
            setNextPayment();
        }
    }

    function setMembers(uint256 _quantity) private {
        address[] memory members_ = getMembers();
        for (uint256 i = 0; i < members_.length; i++) {
            (uint256 percent, ) = getMember(members_[i]);
            pay(members_[i], (_quantity * percent) / 100);
        }
    }

    function pay(address _to, uint256 _amount) private {
        _escrow.deposit{value: _amount}(_to);
        _escrow.withdraw(payable(_to));
    }

    function refund() public onlyOwner atStage(Stages.CREATION) {
        _escrow.deposit{value: getTotal()}(getInvestor());
        _escrow.withdraw(payable(getInvestor()));
    }

    function payTo(address _to)
        public
        payable
        onlyOwner
        atStage(Stages.CREATION)
    {
        _escrow.deposit{value: msg.value}(_to);
        _escrow.withdraw(payable(_to));
        setTotal(getInvestor());
    }

    function sign(address _member) public timeReady withFunds {
        signMember(_member);
        bool start = allSigned();
        if (start) {
            setStage(Stages.RUNNING);
            exec();
        }
    }
}

// File: Trato.sol

pragma solidity >=0.6.2;

contract Trato is TimeDispersions {
    bytes private hash_;

    constructor(address trato) public {
        setTratoClock(trato);
    }

    function setHash(bytes memory _hash) public onlyOwner {
        hash_ = _hash;
    }

    function getHash() public view returns (bytes memory) {
        return hash_;
    }
}
