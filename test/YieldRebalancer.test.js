const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("YieldRebalancer", function () {
  let YieldRebalancer;
  let yieldRebalancer;
  let owner;
  let addr1;
  let safeContractAddress;
  let adminAddress;
  let aaveLendingPoolAddress;
  let aaveDataProviderAddress;
  let usdcPriceFeedAddress;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    safeContractAddress = addr1.address;
    adminAddress = owner.address;
    aaveLendingPoolAddress = addr1.address;
    aaveDataProviderAddress = addr1.address;
    usdcPriceFeedAddress = addr1.address;

    YieldRebalancer = await ethers.getContractFactory("YieldRebalancer");
    yieldRebalancer = await YieldRebalancer.deploy(
      safeContractAddress,
      adminAddress,
      aaveLendingPoolAddress,
      aaveDataProviderAddress,
        usdcPriceFeedAddress
    );
    await yieldRebalancer.deployed();
  });

  it("Should register a new liquidity pool", async function () {
    const poolId = "pool1";
    const poolName = "Test Pool";
    const tokenAddress = addr1.address;
    const apyOracleAddress = addr1.address;
    const isAavePool = true;
    await yieldRebalancer.registerLiquidityPool(poolId, poolName, tokenAddress, apyOracleAddress, isAavePool);

    const pool = await yieldRebalancer.getPoolDetails(poolId);
    expect(pool[0]).to.equal(poolName);
    expect(pool[1]).to.equal(tokenAddress);
      expect(pool[2]).to.equal(apyOracleAddress);
     expect(pool[3]).to.equal(isAavePool);
  });

    it("Should update pool balance", async function () {
      const poolId = "pool1";
      const poolName = "Test Pool";
      const tokenAddress = addr1.address;
        const apyOracleAddress = addr1.address;
      const isAavePool = false;
        await yieldRebalancer.registerLiquidityPool(poolId, poolName, tokenAddress, apyOracleAddress, isAavePool);

        const newBalance = 1000;
      await yieldRebalancer.updatePoolBalance(poolId, newBalance);

        const pool = await yieldRebalancer.getPoolDetails(poolId);
      expect(await yieldRebalancer.liquidityPools(poolId).currentBalance).to.equal(newBalance);

    });

    it("Should set rebalance threshold", async function () {
      const newThreshold = 300;
      await yieldRebalancer.setMinRebalanceThreshold(newThreshold);
      expect(await yieldRebalancer.minRebalanceThreshold()).to.equal(newThreshold);
    });

    it("Should set safety margin", async function () {
      const newMargin = 20;
      await yieldRebalancer.setSafetyMarginApplied(newMargin);
      expect(await yieldRebalancer.safetyMarginApplied()).to.equal(newMargin);
    });


  it("Should revert if rebalance to pool does not have a higher apy", async function () {
       const poolId = "pool1";
      const poolName = "Test Pool";
       const tokenAddress = addr1.address;
      const apyOracleAddress = addr1.address;
      const isAavePool = true;

      const poolId2 = "pool2";
      const poolName2 = "Test Pool2";
       const tokenAddress2 = addr1.address;
      const apyOracleAddress2 = addr1.address;
      const isAavePool2 = false;

     await yieldRebalancer.registerLiquidityPool(poolId, poolName, tokenAddress, apyOracleAddress, isAavePool);
    await yieldRebalancer.registerLiquidityPool(poolId2, poolName2, tokenAddress2, apyOracleAddress2, isAavePool2);

     await expect(yieldRebalancer.executeRebalance(poolId2, poolId, 100)).to.be.revertedWith("Rebalance target APY must be higher");
   });


   it("Should revert if rebalance threshold is not reached", async function () {
          const poolId = "pool1";
          const poolName = "Test Pool";
            const tokenAddress = addr1.address;
          const apyOracleAddress = addr1.address;
      const isAavePool = false;

       const poolId2 = "pool2";
      const poolName2 = "Test Pool2";
        const tokenAddress2 = addr1.address;
      const apyOracleAddress2 = addr1.address;
      const isAavePool2 = true;

       await yieldRebalancer.registerLiquidityPool(poolId, poolName, tokenAddress, apyOracleAddress, isAavePool);
    await yieldRebalancer.registerLiquidityPool(poolId2, poolName2, tokenAddress2, apyOracleAddress2, isAavePool2);

     await expect(yieldRebalancer.executeRebalance(poolId, poolId2, 100)).to.be.revertedWith("APY difference is below the minimum threshold.");
   });
});