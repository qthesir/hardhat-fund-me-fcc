// import
// main function
// calling of main function. This is what we did last time. Hardhat deploy is a little bit different
// Going to call a function we specify

function deployFunc() {
    console.log("hi!");
}

module.exports.default = deployFunc;

const {
    networkConfig,
    developmentChains,
} = require("../helper-hardhat-config");
const { network } = require("hardhat");
const { verify } = require("../utils/verify");

module.exports = async (hre) => {
    const { getNamedAccounts, deployments } = hre;
    // can also pass the hre variables directly into the function parameters (i.e. in the parentheses two lines above)
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId;

    // if chainId is X, use address Y
    // const ethUsdPriceFeed = networkConfig[chainId]["ethUsdPriceFeed"];
    let ethUsdPriceFeedAddress;
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator");
        ethUsdPriceFeedAddress = ethUsdAggregator.address;
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
    }
    // when going for localhost or hardhat network we want to use a mock
    // what happens when we want to change chains?
    const args = [ethUsdPriceFeedAddress];
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args);
    }
    log("-----------------------");
};

module.exports.tags = ["all", "fundme"];
