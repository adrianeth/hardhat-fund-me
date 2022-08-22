// imports

// main function

// calling of main function

// function deployFunc(hre) {
//     console.log("Hi")
// }

// module.exports.default = deployFunc

// module.exports = async (hre) => {
//     const { getNamedAccounts, deployments } = hre
//     // hre.getNamedAccounts & hre.deployments
// }

// const helperConfig = require("../helper-hardhat-config")
// const networkConfig = helperConfig.networkConfig
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network, getNamedAccounts, deployments } = require("hardhat")
require("dotenv").config()
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // if chainId is X use address Y
    // if chainId is Z use address A

    // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]

    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
        log(ethUsdPriceFeedAddress)
    }

    // if the contract doesn't exist, we deploy a minimal version
    // for our local testing

    // when going for localhost or hardhat network
    // we want to use a mock

    // what happens when we want to change chains?

    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: [
            ethUsdPriceFeedAddress,
            /* address? */
        ], // put price feed address in here
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`FundMe deployed at ${fundMe.address}`)

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, [ethUsdPriceFeedAddress])
    }
    log("---------------------------------")
}

module.exports.tags = ["all", "fundme"]
