import { useState } from "react";
import {
  WagmiConfig,
  createConfig,
  useAccount,
  useConnect,
  useDisconnect,
} from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { metaMask } from "@wagmi/connectors";
import { mainnet } from "wagmi/chains";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "./contractConfig";

const config = createConfig({
  autoConnect: true,
  connectors: [metaMask()],
  chains: [mainnet],
});

const queryClient = new QueryClient();

function WalletSection() {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect({ connector: metaMask() });
  const { disconnect } = useDisconnect();

  return (
    <div>
      {isConnected ? (
        <>
          <p>Connected wallet: {address}</p>
          <button onClick={() => disconnect()}>Disconnect</button>
        </>
      ) : (
        <button onClick={() => connect()}>Connect Wallet</button>
      )}
    </div>
  );
}

function App() {
  const contractAddressSet = Boolean(
    CONTRACT_ADDRESS && CONTRACT_ADDRESS.length > 0
  );
  const abiSet = Array.isArray(CONTRACT_ABI) && CONTRACT_ABI.length > 0;

  return (
    <QueryClientProvider client={queryClient}>
      <WagmiConfig config={config}>
        <div style={{ padding: "2rem" }}>
          <h1>TrueFund DApp</h1>
          <WalletSection />
          <div style={{ marginTop: "2rem" }}>
            <p>
              <strong>Contract address:</strong>{" "}
              <code>{contractAddressSet ? CONTRACT_ADDRESS : "Not set"}</code>
            </p>
            {!contractAddressSet && (
              <p style={{ color: "orange" }}>
                Please set your deployed contract address in{" "}
                <code>src/contractConfig.js</code>.
              </p>
            )}
            {!abiSet && (
              <p style={{ color: "orange" }}>
                Please paste your contract ABI array in{" "}
                <code>src/contractConfig.js</code>.
              </p>
            )}
            {contractAddressSet && abiSet ? (
              <p>Integrate contract features below...</p>
            ) : (
              <p style={{ color: "gray" }}>
                Waiting for contract configuration. Wallet connect is available
                above.
              </p>
            )}
          </div>
        </div>
      </WagmiConfig>
    </QueryClientProvider>
  );
}

export default App;
