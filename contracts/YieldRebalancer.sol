// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@safe-global/safe-contracts/contracts/Safe.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IDataProvider.sol";

contract YieldRebalancer {
    // Safe contract address
    address public safeContractAddress;

    // Addresses of Aave Lending Pool, Data Provider, and price feeds.
    address public aaveLendingPool;
    address public aaveDataProvider;
    address public usdcPriceFeed;

    // Data structures
    struct LiquidityPool {
        string name;
        address tokenAddress;
        address apyOracleAddress;
        uint256 currentBalance;
        bool isAavePool;
    }

    mapping(bytes32 => LiquidityPool) public liquidityPools;
    bytes32[] public poolIds;

    uint256 public safetyMarginApplied = 10;
    uint256 public minRebalanceThreshold = 200;
    uint256 public lastRebalanceTime;
    address public immutable admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    event Rebalanced(
        address indexed rebalancer,
        bytes32 fromPoolId,
        bytes32 toPoolId,
        uint256 amount,
        uint256 newBalance
    );

    event PoolAdded(
        bytes32 poolId,
        string name,
        address tokenAddress,
        address apyOracleAddress,
        bool isAavePool
    );

    constructor(
        address _safeContractAddress,
        address _admin,
        address _aaveLendingPool,
        address _aaveDataProvider,
        address _usdcPriceFeed
    ) {
        safeContractAddress = _safeContractAddress;
        admin = _admin;
        aaveLendingPool = _aaveLendingPool;
        aaveDataProvider = _aaveDataProvider;
        usdcPriceFeed = _usdcPriceFeed;
    }

    function registerLiquidityPool(
        bytes32 _poolId,
        string memory _name,
        address _tokenAddress,
        address _apyOracleAddress,
        bool _isAavePool
    ) external onlyAdmin {
        require(liquidityPools[_poolId].tokenAddress == address(0), "Pool already exists");
        liquidityPools[_poolId] = LiquidityPool({
            name: _name,
            tokenAddress: _tokenAddress,
            apyOracleAddress: _apyOracleAddress,
            currentBalance: 0,
            isAavePool: _isAavePool
        });
        poolIds.push(_poolId);
        emit PoolAdded(_poolId, _name, _tokenAddress, _apyOracleAddress, _isAavePool);
    }

    function updatePoolBalance(bytes32 _poolId, uint256 _newBalance) external onlyAdmin {
        liquidityPools[_poolId].currentBalance = _newBalance;
    }

    function updatePoolApyOracle(bytes32 _poolId, address _apyOracleAddress) external onlyAdmin {
        liquidityPools[_poolId].apyOracleAddress = _apyOracleAddress;
    }

    function setMinRebalanceThreshold(uint256 _minRebalanceThreshold) external onlyAdmin {
        minRebalanceThreshold = _minRebalanceThreshold;
    }

    function setSafetyMarginApplied(uint256 _safetyMarginApplied) external onlyAdmin {
        safetyMarginApplied = _safetyMarginApplied;
    }

    // Aave deposit function
    function depositToAave(bytes32 _poolId, uint256 _amount) internal onlyAdmin {
        require(liquidityPools[_poolId].isAavePool, "Must be an Aave pool");
        ILendingPool lendingPool = ILendingPool(aaveLendingPool);
        address asset = liquidityPools[_poolId].tokenAddress;

        lendingPool.deposit(
            asset,
            _amount,
            address(this), // Deposit on behalf of this contract
            0 // referral code
        );
        liquidityPools[_poolId].currentBalance += _amount;
    }

    // Aave withdraw function
    function withdrawFromAave(bytes32 _poolId, uint256 _amount) internal onlyAdmin returns (uint256) {
        require(liquidityPools[_poolId].isAavePool, "Must be an Aave pool");
        ILendingPool lendingPool = ILendingPool(aaveLendingPool);
        address asset = liquidityPools[_poolId].tokenAddress;

        uint256 actualAmountWithdrawn = lendingPool.withdraw(asset, _amount, address(this));
        liquidityPools[_poolId].currentBalance -= actualAmountWithdrawn;
        return actualAmountWithdrawn;
    }

    // Aave borrow function
    function borrowFromAave(bytes32 _poolId, uint256 _amount) internal onlyAdmin {
        require(liquidityPools[_poolId].isAavePool, "Must be an Aave pool");
        ILendingPool lendingPool = ILendingPool(aaveLendingPool);
        address asset = liquidityPools[_poolId].tokenAddress;

        lendingPool.borrow(
            asset,
            _amount,
            2, // Variable interest rate mode
            0,
            address(this)
        );
    }

    // Aave repay function
    function repayToAave(bytes32 _poolId, uint256 _amount) internal onlyAdmin {
         require(liquidityPools[_poolId].isAavePool, "Must be an Aave pool");
        ILendingPool lendingPool = ILendingPool(aaveLendingPool);
        address asset = liquidityPools[_poolId].tokenAddress;

        lendingPool.repay(asset, _amount, 2, address(this));
    }

   function executeRebalance(bytes32 _fromPoolId, bytes32 _toPoolId, uint256 _amount) external onlyAdmin {
         require(liquidityPools[_fromPoolId].tokenAddress != address(0), "Invalid From Pool");
        require(liquidityPools[_toPoolId].tokenAddress != address(0), "Invalid To Pool");

         uint256 fromApy = getPoolApyFromOracle(liquidityPools[_fromPoolId].apyOracleAddress);
         uint256 toApy = getPoolApyFromOracle(liquidityPools[_toPoolId].apyOracleAddress);

        uint256 apyDiff = toApy - fromApy;

        require(apyDiff > 0, "Rebalance target APY must be higher");
        require(apyDiff > minRebalanceThreshold, "APY difference is below the minimum threshold.");

        // Add a check to ensure some time has passed since the last rebalance to prevent constant txs
        require(block.timestamp > lastRebalanceTime + 1 days, "Too soon to rebalance");

        uint256 amountWithSafetyMargin =  _amount * (10000 - safetyMarginApplied) / 10000 ; //Simulate a safety margin adjustment

          if (liquidityPools[_fromPoolId].isAavePool) {
              withdrawFromAave(_fromPoolId, amountWithSafetyMargin);
          } else {
              //Encode a transaction to transfer from another pool
              // Encode the function call data to be sent to the safe
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", liquidityPools[_toPoolId].tokenAddress, amountWithSafetyMargin);
             Safe safe = Safe(safeContractAddress);
             (bool success, bytes memory returnData) =  safe.execTransaction{gas: 500000}(
                address(this),
                0,
                data,
                Safe.Operation.CALL,
                500000,
                0,
                0,
                address(0),
                address(0),
                ""
             );
             require(success, "Transaction Failed");
          }


          if (liquidityPools[_toPoolId].isAavePool) {
                depositToAave(_toPoolId, amountWithSafetyMargin);
         } else {
            // Encode a transaction to transfer to another pool
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", liquidityPools[_toPoolId].tokenAddress, amountWithSafetyMargin);
            Safe safe = Safe(safeContractAddress);
           (bool success, bytes memory returnData) =  safe.execTransaction{gas: 500000}(
                address(this),
                0,
                data,
                Safe.Operation.CALL,
                500000,
                0,
                0,
                address(0),
                address(0),
                ""
            );
            require(success, "Transaction Failed");
        }
        lastRebalanceTime = block.timestamp;

        emit Rebalanced(msg.sender, _fromPoolId, _toPoolId, amountWithSafetyMargin, 0);
    }

    function getPoolApyFromOracle(address _oracleAddress) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracleAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //Return price or compute APY if required.
        return uint256(price);
    }

    function getPoolDetails(bytes32 poolId)
        external
        view
        returns (
            string memory,
            address,
            address,
            bool
        )
    {
        return (
            liquidityPools[poolId].name,
            liquidityPools[poolId].tokenAddress,
            liquidityPools[poolId].apyOracleAddress,
            liquidityPools[poolId].isAavePool
        );
    }

    function getAllPoolIds() external view returns (bytes32[] memory) {
        return poolIds;
    }

    function getMinRebalanceThreshold() external view returns (uint256) {
        return minRebalanceThreshold;
    }

    function getSafetyMarginApplied() external view returns (uint256) {
        return safetyMarginApplied;
    }

    function getLastRebalanceTime() external view returns (uint256) {
        return lastRebalanceTime;
    }
}