// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Aave V3 IPool interface (simplificada)
interface IPool {
    function getReserveData(address asset) external view returns (
        // Simplificando, normalmente son más campos
        uint256, // configuration
        uint128, // liquidityIndex
        uint128, // variableBorrowIndex
        uint128, // currentLiquidityRate
        uint128, // currentVariableBorrowRate
        uint128, // currentStableBorrowRate
        uint40,  // lastUpdateTimestamp
        address, // aTokenAddress
        address, // stableDebtTokenAddress
        address, // variableDebtTokenAddress
        address, // interestRateStrategyAddress
        uint8    // id
    );
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
}

// Compound CEther interface (solo lo necesario)
interface ICEther {
    function borrow(uint256 borrowAmount) external returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
}

contract LoanOptimizer {
    IPool public aavePool;
    ICEther public cEth;
    
    enum Protocol { AAVE, COMPOUND }
    
    event LoanExecuted(
        address indexed user,
        Protocol protocol,
        uint256 amount,
        bool isBorrowing
    );

    constructor(address _aavePool, address _cEth) {
        aavePool = IPool(_aavePool);
        cEth = ICEther(_cEth);
    }

    function getBestBorrowRate() public view returns (Protocol) {
        // Simplificado: estos valores NO son comparables directamente en producción
        // Solo ejemplo de estructura
        (, , , , uint128 aaveVariableBorrowRate, , , , , , ,) = aavePool.getReserveData(address(0));
        uint256 aaveRate = uint256(aaveVariableBorrowRate); // Normalmente hay que escalarlo
        uint256 compoundRate = cEth.borrowRatePerBlock() * 2102400; // APR estimado

        return aaveRate < compoundRate ? Protocol.AAVE : Protocol.COMPOUND;
    }

    function executeBorrow(uint256 amount) external {
        Protocol best = getBestBorrowRate();
        
        if (best == Protocol.AAVE) {
            aavePool.borrow(address(0), amount, 2, 0, msg.sender); // 2: variable interest rate
        } else {
            require(cEth.borrow(amount) == 0, "Compound borrow failed");
            // Aquí deberías transferir cETH, no ETH directamente
            // payable(msg.sender).transfer(amount); // Incorrecto
        }
        
        emit LoanExecuted(msg.sender, best, amount, true);
    }
}