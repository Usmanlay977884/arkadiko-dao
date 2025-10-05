
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const deployer = accounts.get("deployer")!;

describe("Arkadiko Token (ARE) Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should have correct token metadata", () => {
    const name = simnet.callReadOnlyFn("arkadiko-token", "get-name", [], deployer);
    const symbol = simnet.callReadOnlyFn("arkadiko-token", "get-symbol", [], deployer);
    const decimals = simnet.callReadOnlyFn("arkadiko-token", "get-decimals", [], deployer);
    
    expect(name.result).toBeOk("Arkadiko Token");
    expect(symbol.result).toBeOk("ARE");
    expect(decimals.result).toBeOk(6);
  });

  it("should initialize with correct total supply for deployer", () => {
    const totalSupply = simnet.callReadOnlyFn("arkadiko-token", "get-total-supply", [], deployer);
    const deployerBalance = simnet.callReadOnlyFn("arkadiko-token", "get-balance", [deployer], deployer);
    
    expect(totalSupply.result).toBeOk(1000000000); // 1 billion tokens
    expect(deployerBalance.result).toBeOk(1000000000);
  });

  it("should allow deployer to transfer tokens", () => {
    const transferResult = simnet.callPublicFn(
      "arkadiko-token",
      "transfer",
      [100000, deployer, address1, null],
      deployer
    );
    
    expect(transferResult.result).toBeOk(true);
    
    const address1Balance = simnet.callReadOnlyFn("arkadiko-token", "get-balance", [address1], deployer);
    expect(address1Balance.result).toBeOk(100000);
  });

  it("should allow authorized contracts to mint tokens", () => {
    // First authorize the deployer as a contract
    const authResult = simnet.callPublicFn(
      "arkadiko-token",
      "authorize-contract",
      [deployer],
      deployer
    );
    expect(authResult.result).toBeOk(true);
    
    // Now mint tokens
    const mintResult = simnet.callPublicFn(
      "arkadiko-token",
      "mint",
      [50000, address2],
      deployer
    );
    expect(mintResult.result).toBeOk(true);
    
    const address2Balance = simnet.callReadOnlyFn("arkadiko-token", "get-balance", [address2], deployer);
    expect(address2Balance.result).toBeOk(50000);
  });

  it("should not allow unauthorized users to mint tokens", () => {
    const mintResult = simnet.callPublicFn(
      "arkadiko-token",
      "mint",
      [50000, address2],
      address1
    );
    expect(mintResult.result).toBeErr(100); // ERR_NOT_AUTHORIZED
  });

  it("should allow authorized contracts to burn tokens", () => {
    const burnResult = simnet.callPublicFn(
      "arkadiko-token",
      "burn",
      [25000, address2],
      deployer
    );
    expect(burnResult.result).toBeOk(true);
    
    const address2Balance = simnet.callReadOnlyFn("arkadiko-token", "get-balance", [address2], deployer);
    expect(address2Balance.result).toBeOk(25000); // 50000 - 25000
  });
});
