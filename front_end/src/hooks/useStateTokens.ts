import { useEffect, useState } from "react"
import { useEthers, useContractFunction } from "@usedapp/core"
import { constants, utils } from "ethers"
import TokenFarm from "../chain-info/contracts/TokenFarm.json"
import ERC20 from "../chain-info/contracts/MockERC20.json"
import { Contract } from "@ethersproject/contracts"
import networkMapping from "../chain-info/deployments/map.json"

export const useStakeTokens = (tokenAddress: string) => {
    // address
    // abi
    // chainId
    const { chainId } = useEthers()
    // This is import from chain-info
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    // Use Address and Interface to get contract
    const tokenFarmContract = new Contract(tokenFarmAddress, tokenFarmInterface)

    // From MockERC20.json
    const erc20ABI = ERC20.abi
    const erc20Interface = new utils.Interface(erc20ABI)
    // Use Address and Interface to get contract
    const erc20Contract = new Contract(tokenAddress, erc20Interface)
    // approve, useContractFunction returns a send and state
    const { send: approveErc20Send, state: approveAndStakeErc20State } =
        useContractFunction(erc20Contract, "approve", {
            transactionName: "Approve ERC20 transfer",
        })
    const approveAndStake = (amount: string) => {
        setAmountToStake(amount)
        return approveErc20Send(tokenFarmAddress, amount)
    }
    // stake
    const { send: stakeSend, state: stakeState } =
        useContractFunction(tokenFarmContract, "stakeTokens", {
            transactionName: "Stake Tokens",
        })
    // This is for how much we cant to stake
    const [amountToStake, setAmountToStake] = useState("0")

    // useEffect, this allows us to do something if a variable has changed. If anything in our array changes then we do something
    useEffect(() => {
        if (approveAndStakeErc20State.status === "Success") {
            stakeSend(amountToStake, tokenAddress)
        }
    }, [approveAndStakeErc20State, amountToStake, tokenAddress])

    // This is our overall state state variable 
    const [state, setState] = useState(approveAndStakeErc20State)

    // This is the overall state of both approve and stake states
    useEffect(() => {
        if (approveAndStakeErc20State.status === "Success") {
            setState(stakeState)
        } else {
            setState(approveAndStakeErc20State)
        }
    }, [approveAndStakeErc20State, stakeState])


    return { approveAndStake, state }
}