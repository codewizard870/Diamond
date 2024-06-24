// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { network, run } = require("hardhat")

const { deployApiConsumer } = require("./deployApiConsumer")
const { deployAutomationCounter } = require("./deployAutomationCounter")
const { deployPriceConsumerV3 } = require("./deployPriceConsumerV3")
const { deployRandomNumberConsumer } = require("./deployRandomNumberConsumer")
const {
    deployRandomNumberDirectFundingConsumer,
} = require("./deployRandomNumberDirectFundingConsumer")

async function main() {
    // await run("compile")
    // const chainId = network.config.chainId
    // await deployApiConsumer(chainId)
    // await deployAutomationCounter(chainId)
    // await deployPriceConsumerV3(chainId)
    // await deployBeCostomize(chainId)
    // await deployRandomNumberConsumer(chainId)
    // await deployRandomNumberDirectFundingConsumer(chainId)

    const [deployer] = await ethers.getSigners()

    console.log("Deploying contracts with the account:", deployer.address)
    let logicBe, LogicBe, MainBe, mainBe

    LogicBe = await ethers.getContractFactory("LogicBe")
    logicBe = await LogicBe.deploy()
    await logicBe.deployed()

    MainBe = await ethers.getContractFactory("MainBe")
    mainBe = await MainBe.deploy(logicBe.address)
    await mainBe.deployed()
    // const bes = await mainBe.getAllbes()
    console.log("Logic contract address: ", logicBe.address,"Main contract address: ", mainBe.address)
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
