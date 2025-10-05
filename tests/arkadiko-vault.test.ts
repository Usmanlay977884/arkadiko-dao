
import { describe, expect, it, beforeEach } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const deployer = accounts.get("deployer")!;

describe("Arkadiko Vault Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should have correct DIKO token metadata", () => {
    const name = simnet.callReadOnlyFn("arkadiko-vault", "get-diko-name", [], deployer);
    const symbol = simnet.callReadOnlyFn("arkadiko-vault", "get-diko-symbol", [], deployer);
    const decimals = simnet.callReadOnlyFn("arkadiko-vault", "get-diko-decimals", [], deployer);
    
    expect(name.result).toBeOk("DIKO Stablecoin");
    expect(symbol.result).toBeOk("DIKO");
    expect(decimals.result).toBeOk(6);
  });

  it("should allow user to create a vault with STX collateral", () => {
    const collateralAmount = 1000000000; // 1000 STX
    
    const createVaultResult = simnet.callPublicFn(
      "arkadiko-vault",
      "create-vault",
      [collateralAmount],
      address1
    );
    
    expect(createVaultResult.result).toBeOk(1); // First vault ID
    
    // Check vault was created correctly
    const vault = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-vault",
      [1],
      deployer
    );
    
    expect(vault.result).toBeSome();
  });

  it("should allow vault owner to mint DIKO against collateral", () => {
    // First create a vault
    const collateralAmount = 2000000000; // 2000 STX
    simnet.callPublicFn(
      "arkadiko-vault",
      "create-vault",
      [collateralAmount],
      address1
    );
    
    // Mint DIKO (should be less than collateral value / 150%)
    const mintAmount = 1000000000; // 1000 DIKO
    const mintResult = simnet.callPublicFn(
      "arkadiko-vault",
      "mint-diko",
      [2, mintAmount], // vault-id 2, amount
      address1
    );
    
    expect(mintResult.result).toBeOk(true);
    
    // Check DIKO balance
    const dikoBalance = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-diko-balance",
      [address1],
      deployer
    );
    expect(dikoBalance.result).toBeOk(mintAmount);
  });

  it("should not allow minting beyond collateral ratio limits", () => {
    // Create vault with minimal collateral
    const collateralAmount = 150000000; // 150 STX
    simnet.callPublicFn(
      "arkadiko-vault",
      "create-vault",
      [collateralAmount],
      address2
    );
    
    // Try to mint too much DIKO (would create under-collateralized position)
    const excessiveMintAmount = 200000000; // 200 DIKO (more than collateral allows)
    const mintResult = simnet.callPublicFn(
      "arkadiko-vault",
      "mint-diko",
      [3, excessiveMintAmount], // vault-id 3
      address2
    );
    
    expect(mintResult.result).toBeErr(301); // ERR_INSUFFICIENT_COLLATERAL
  });

  it("should allow vault owner to repay DIKO debt", () => {
    // Use existing vault with debt from previous test
    const repayAmount = 500000000; // 500 DIKO
    
    const repayResult = simnet.callPublicFn(
      "arkadiko-vault",
      "repay-diko",
      [2, repayAmount], // vault-id 2
      address1
    );
    
    expect(repayResult.result).toBeOk(repayAmount);
    
    // Check reduced DIKO balance
    const dikoBalance = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-diko-balance",
      [address1],
      deployer
    );
    expect(dikoBalance.result).toBeOk(500000000); // 1000 - 500
  });

  it("should allow vault owner to add more collateral", () => {
    const additionalCollateral = 500000000; // 500 STX
    
    const addCollateralResult = simnet.callPublicFn(
      "arkadiko-vault",
      "add-collateral",
      [2, additionalCollateral], // vault-id 2
      address1
    );
    
    expect(addCollateralResult.result).toBeOk(true);
    
    // Check vault has more collateral
    const vault = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-vault",
      [2],
      deployer
    );
    
    expect(vault.result).toBeSome();
  });

  it("should track user's vaults correctly", () => {
    const userVaults = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-user-vaults",
      [address1],
      deployer
    );
    
    expect(userVaults.result).toBeList();
  });

  it("should calculate collateral ratio for vault with debt", () => {
    const collateralRatio = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "calculate-collateral-ratio",
      [2], // vault-id 2 has debt
      deployer
    );
    
    expect(collateralRatio.result).toBeSome();
  });

  it("should track total debt across all vaults", () => {
    const totalDebt = simnet.callReadOnlyFn(
      "arkadiko-vault",
      "get-total-debt",
      [],
      deployer
    );
    
    expect(totalDebt.result).toBeGreaterThan(0);
  });

  it("should not allow non-owners to modify vaults", () => {
    const mintResult = simnet.callPublicFn(
      "arkadiko-vault",
      "mint-diko",
      [2, 100000000], // Try to mint from address1's vault
      address2 // But as address2
    );
    
    expect(mintResult.result).toBeErr(300); // ERR_NOT_AUTHORIZED
  });
});
