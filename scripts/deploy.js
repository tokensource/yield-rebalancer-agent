const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
    const safeContractAddress = process.env.SAFE_CONTRACT_ADDRESS;
    const adminAddress = process.env.ADMIN_ADDRESS;
    const aaveLendingPoolAddress = process.env.AAVE_LENDING_POOL_ADDRESS;
    const aaveDataProviderAddress = process.env.AAVE_DATA_PROVIDER_ADDRESS;
    const usdcPriceFeedAddress = process.env.USDC_PRICE_FEED_ADDRESS;


    const YieldRebalancer = await ethers.getContractFactory("YieldRebalancer");
    const yieldRebalancer = await YieldRebalancer.deploy(
        safeContractAddress,
        adminAddress,
        aaveLendingPoolAddress,
        aaveDataProviderAddress,
        usdcPriceFeedAddress
    );

    await yieldRebalancer.deployed();

    console.log("YieldRebalancer deployed to:", yieldRebalancer.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });