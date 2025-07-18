"use client";

import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { PropsWithChildren, createContext, useContext } from "react";
import { Network } from "@aptos-labs/ts-sdk";
import { toast } from "react-toastify";
import { useAutoConnect } from "./auto-connect-provider";

// Create a simple SDK context to fix the useSDK error
const SDKContext = createContext<any>(null);

export const useSDK = () => {
  const context = useContext(SDKContext);
  if (!context) {
    throw new Error("useSDK was used outside the SDKProvider");
  }
  return context;
};

export const WalletProvider = ({ children }: PropsWithChildren) => {
  const notifyError = (error: any) => toast.error(error?.message || error || "Unknown wallet error");

  const { autoConnect } = useAutoConnect();

  return (
    <SDKContext.Provider value={{ network: Network.TESTNET }}>
      <AptosWalletAdapterProvider
        autoConnect={autoConnect}
        dappConfig={{
          network:
            (process.env.NEXT_PUBLIC_APP_NETWORK as Network) ?? Network.TESTNET,
          aptosConnect: {
            dappName: "Aptos Markets Predictions",
            dappImageURI: "https://aptos-markets.vercel.app/aptos_markets_logo.png",
          },
          mizuwallet: {
            manifestURL:
              "https://assets.mz.xyz/static/config/mizuwallet-connect-manifest.json",
          },
        }}
        onError={notifyError}
      >
        {children}
      </AptosWalletAdapterProvider>
    </SDKContext.Provider>
  );
};
