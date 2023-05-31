// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "forge-std/Test.sol";
import {TokenFixture} from "./utils/TokenFixture.sol";
import {IPoolManager} from "../../contracts/interfaces/IPoolManager.sol";
import {IHooks} from "../../contracts/interfaces/IHooks.sol";
import {PoolManager} from "../../contracts/PoolManager.sol";
import {PoolDonateTest} from "../../contracts/test/PoolDonateTest.sol";
import {TickMath} from "../../contracts/libraries/TickMath.sol";
import {Pool} from "../../contracts/libraries/Pool.sol";
import {PoolId} from "../../contracts/libraries/PoolId.sol";
import {PoolGetters} from "../../contracts/libraries/PoolGetters.sol";
import {Deployers} from "./utils/Deployers.sol";
import {TokenFixture} from "./utils/TokenFixture.sol";
import {PoolModifyPositionTest} from "../../contracts/test/PoolModifyPositionTest.sol";
import {Currency, CurrencyLibrary} from "../../contracts/libraries/CurrencyLibrary.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {PoolLockTest} from "../../contracts/test/PoolLockTest.sol";
import {IERC20Minimal} from "../../contracts/interfaces/external/IERC20Minimal.sol";
import {PoolSwapTest} from "../../contracts/test/PoolSwapTest.sol";

contract PoolGettersTest is Test, TokenFixture, Deployers, GasSnapshot {
    using PoolGetters for IPoolManager;

    Pool.State state;
    IPoolManager manager;
    PoolSwapTest swapRouter;

    PoolModifyPositionTest modifyPositionRouter;
    IPoolManager.PoolKey key;
    bytes32 poolId;

    address ADDRESS_ZERO = address(0);
    IHooks zeroHooks = IHooks(ADDRESS_ZERO);

    function setUp() public {
        (manager, key,) = Deployers.createFreshPool(zeroHooks, 3000, SQRT_RATIO_1_1);
        poolId = PoolId.toId(key);
        currency0 = key.currency0;
        currency1 = key.currency1;
        modifyPositionRouter = new PoolModifyPositionTest(manager);
        swapRouter = new PoolSwapTest(IPoolManager(address(manager)));

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 10 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 10 ether);

        MockERC20(Currency.unwrap(currency0)).approve(address(modifyPositionRouter), 10 ether);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyPositionRouter), 10 ether);
        IERC20Minimal(Currency.unwrap(key.currency1)).approve(address(swapRouter), 10 ** 18);

        // populate pool storage data
        modifyPositionRouter.modifyPosition(key, IPoolManager.ModifyPositionParams(-120, 120, 5 ether));
        swapRouter.swap(
            key, IPoolManager.SwapParams(false, 1 ether, TickMath.MAX_SQRT_RATIO - 1),
            PoolSwapTest.TestSettings(true, true)
        );
    }

    function testGetPoolPriceGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetSqrtPriceFromGettersLibrary");
        uint160 sqrtPriceX96Getter = manager.getPoolPrice(_poolId);
        snapEnd();

        (uint160 sqrtPriceX96Slot0, , ) = manager.getSlot0(_poolId);
        assertEq(sqrtPriceX96Getter, sqrtPriceX96Slot0);
    }

    function testGetSlot0() public {
        bytes32 _poolId = poolId;

        snapStart("poolGetSqrtPriceFromSlot0");
        manager.getSlot0(_poolId);
        snapEnd();
    }

    function testGetPoolTickGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetTickFromGettersLibrary");
        int24 tickGetter = manager.getPoolTick(_poolId);
        snapEnd();

        (, int24 tickSlot0, ) = manager.getSlot0(_poolId);
        assertEq(tickGetter, tickSlot0);
    }

    function testGetPoolTickxInternalHelper() public {
        bytes32 _poolId = poolId;

        snapStart("poolGetTickFromSlot0");
        manager.getSlot0(_poolId);
        snapEnd();
    }

    function testGetGrossLiquidityAtTickInteralHelper() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetGrossLiquidityAtTickFromHelperFunction");
        uint128 grossLiquidityHelper = manager.getTickInfo(_poolId, 120).liquidityGross;
        snapEnd();
    }

    function testGetGrossLiquidityAtTickGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetGrossLiquidityAtTickFromGettersLibrary");
        uint128 grossLiquidityGetter = manager.getGrossLiquidityAtTick(_poolId, 120);
        snapEnd();

        uint128 grossLiquidityHelper = manager.getTickInfo(_poolId, 120).liquidityGross;
        assertEq(grossLiquidityGetter, grossLiquidityHelper);
    }

    function testGetNetLiquidityAtTickInteralHelper() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetNetLiquidityAtTickFromHelperFunction");
        int128 netLiquidityHelper = manager.getTickInfo(_poolId, 120).liquidityNet;
        snapEnd();
    }

    function testGetNetLiquidityAtTickGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetNetLiquidityAtTickFromGetters");
        int128 netLiquidityGetter = manager.getNetLiquidityAtTick(_poolId, 120);
        snapEnd();

        int128 netLiquidityHelper = manager.getTickInfo(_poolId, 120).liquidityNet;
        assertEq(netLiquidityGetter, netLiquidityHelper);
    }

    function testGetfeeGrowthOutside0AtTickInteralHelper() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetfeeGrowthOutside0AtTickFromHelperFunction");
        uint256 netLiquidityHelper = manager.getTickInfo(_poolId, 120).feeGrowthOutside0X128;
        snapEnd();
    }

    function testGetfeeGrowthOutside0AtTickGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetfeeGrowthOutside0AtTickFromGetters");
        uint256 netLiquidityGetter = manager.getfeeGrowthOutside0AtTick(_poolId, 120);
        snapEnd();

        uint256 feeGrowthHelper = manager.getTickInfo(_poolId, 120).feeGrowthOutside0X128;
        assertEq(netLiquidityGetter, feeGrowthHelper);
    }

    function testGetfeeGrowthOutside1AtTickInteralHelper() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetfeeGrowthOutside1AtTickFromHelperFunction");
        uint256 netLiquidityHelper = manager.getTickInfo(_poolId, 120).feeGrowthOutside1X128;
        snapEnd();
    }

    function testGetfeeGrowthOutside1AtTickGetter() public {
        bytes32 _poolId = poolId;
        snapStart("poolGetfeeGrowthOutside1AtTickFromGetters");
        uint256 netLiquidityGetter = manager.getfeeGrowthOutside1AtTick(_poolId, 120);
        snapEnd();

        uint256 feeGrowthHelper = manager.getTickInfo(_poolId, 120).feeGrowthOutside1X128;
        assertEq(netLiquidityGetter, feeGrowthHelper);
    }
}
