"use client";

import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { PropsWithChildren } from "react";
import { Network } from "@aptos-labs/ts-sdk";
import { toast } from "react-toastify";
import { useAutoConnect } from "./auto-connect-provider";

export const WalletProvider = ({ children }: PropsWithChildren) => {
  const notifyError = (msg: string) => toast.error(msg);

  const { autoConnect } = useAutoConnect();

  return (
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
      onError={(error) => notifyError(error || "Unknown wallet error")}
    >
      {children}
    </AptosWalletAdapterProvider>
  );
};
