
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const deployer = accounts.get("deployer")!;

describe("Arkadiko Oracle Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should initialize with deployer as authorized source and STX price", () => {
    const isAuthorized = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "is-authorized-source",
      [deployer],
      deployer
    );
    expect(isAuthorized.result).toBe(true);
    
    const stxPrice = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "get-price",
      ["STX"],
      deployer
    );
    expect(stxPrice.result).toBeOk(1000000); // $1.00 in micro-dollars
  });

  it("should allow authorized source to set price", () => {
    const setPriceResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "set-price",
      ["BTC", 50000000000], // $50,000 in micro-dollars
      deployer
    );
    expect(setPriceResult.result).toBeOk(true);
    
    const btcPrice = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "get-price",
      ["BTC"],
      deployer
    );
    expect(btcPrice.result).toBeOk(50000000000);
  });

  it("should not allow unauthorized source to set price", () => {
    const setPriceResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "set-price",
      ["ETH", 3000000000], // $3,000 in micro-dollars
      address1
    );
    expect(setPriceResult.result).toBeErr(200); // ERR_NOT_AUTHORIZED
  });

  it("should allow owner to authorize new source", () => {
    const authResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "authorize-source",
      [address1],
      deployer
    );
    expect(authResult.result).toBeOk(true);
    
    const isAuthorized = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "is-authorized-source",
      [address1],
      deployer
    );
    expect(isAuthorized.result).toBe(true);
  });

  it("should allow newly authorized source to set price", () => {
    const setPriceResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "set-price",
      ["ETH", 3000000000], // $3,000 in micro-dollars
      address1
    );
    expect(setPriceResult.result).toBeOk(true);
    
    const ethPrice = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "get-price",
      ["ETH"],
      deployer
    );
    expect(ethPrice.result).toBeOk(3000000000);
  });

  it("should allow owner to revoke source authorization", () => {
    const revokeResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "revoke-source",
      [address1],
      deployer
    );
    expect(revokeResult.result).toBeOk(true);
    
    const isAuthorized = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "is-authorized-source",
      [address1],
      deployer
    );
    expect(isAuthorized.result).toBe(false);
  });

  it("should return price info with timestamp and source", () => {
    const priceInfo = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "get-price-info",
      ["STX"],
      deployer
    );
    expect(priceInfo.result).toBeSome();
  });

  it("should allow owner to transfer ownership", () => {
    const transferResult = simnet.callPublicFn(
      "arkadiko-oracle",
      "transfer-ownership",
      [address2],
      deployer
    );
    expect(transferResult.result).toBeOk(true);
    
    const newOwner = simnet.callReadOnlyFn(
      "arkadiko-oracle",
      "get-owner",
      [],
      deployer
    );
    expect(newOwner.result).toBe(address2);
  });
});
