const { expect } = require("chai")

describe("MainBe", function () {
    let LogicBe, logicBe, MainBe, mainBe, owner

    beforeEach(async function () {
        ;[owner] = await ethers.getSigners()

        LogicBe = await ethers.getContractFactory("LogicTempBE")
        logicBe = await LogicBe.deploy()
        await logicBe.deployed()

        MainBe = await ethers.getContractFactory("MainTempBE")
        mainBe = await MainBe.deploy(logicBe.address)
        await mainBe.deployed()
    })

    it("should delegate call to LogicBe", async function () {
        const beData = [
            "4231",
            "0x0000000000000000000000000000000000000000",
            "Live",
            "Anonymous",
            true,
            false,
            {
                agentId: "0",
                agentName: "ageny0000",
                agentAddress: "WT",
                agentTelephone: "78",
                agentEmail: "@",
                agentAccess: ["abc"],
            },
            [
                {
                    // adminId: "989898",
                    adminAddress: "0x421F64C3f22AeE7BE98a019d7F1D5D23f346c10a",
                    verified: false,
                },
            ],
            [
                {
                    reserveAdminAddress: "0xFFfCd0B404c3d8AE38Ea2966bAD5A75D5Ab6ce0F",
                    verified: false,
                },
            ],
            90,
            "ANY_ONE",
            false,
            [
                {
                    ownerAddress: "0xFFfCd0B404c3d8AE38Ea2966bAD5A75D5Ab6ce0F",
                    ownerShares: "989",
                    ownerAccess: ["abc", "def"],
                    verified: false,
                },
            ],
            false,
            [
                {
                    notificationPartyAddress: "0xFFfCd0B404c3d8AE38Ea2966bAD5A75D5Ab6ce0F",
                    notificationPartyAccess: ["abc", "xyz"],
                    verified: true,
                },
            ],
            [
                {
                    submittedAt: 999,
                    title: 'abc',
                    url: "https:/www"
                }
            ],
            false,
            1749005868,
            1717469868,
            1717469868,
            false,
            1717469868,
            true,
        ]
        await mainBe.registerBE(beData)
        const bes = await mainBe.getAllBes()
        for (const be of bes) {
            console.log(be)
        }
    })
})
