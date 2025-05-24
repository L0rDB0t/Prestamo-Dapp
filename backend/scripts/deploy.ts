import { ethers } from "hardhat";

async function main() {
  const aavePool = "0x5E52dEc931FFb32f609681B8438A51c675cc232d"; // Aave v3 Sepolia
  const cEth = "0x000000000000000000000000000000000000dEaD"; // Dummy address

  const LoanOptimizer = await ethers.getContractFactory("LoanOptimizer");
  const loanOptimizer = await LoanOptimizer.deploy(aavePool, cEth);

  await loanOptimizer.waitForDeployment();

  console.log("LoanOptimizer deployed to:", await loanOptimizer.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});