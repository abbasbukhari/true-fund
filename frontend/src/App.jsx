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
import { ethers } from "ethers";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "./contractConfig";

// Ganache local chain config
const ganacheLocal = {
  id: 1337,
  name: "Ganache Local",
  network: "ganache",
  nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["http://127.0.0.1:7545"] },
    public: { http: ["http://127.0.0.1:7545"] },
  },
};

const config = createConfig({
  autoConnect: true,
  connectors: [metaMask()],
  chains: [ganacheLocal], // Use Ganache chain
});

const queryClient = new QueryClient();

function WalletSection() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isLoading, error } = useConnect();
  const { disconnect } = useDisconnect();

  // Use the first available connector (MetaMask if installed)
  const mmConnector =
    connectors.find((c) => c.name === "MetaMask") || connectors[0];

  return (
    <div>
      {isConnected ? (
        <>
          <p>Connected wallet: {address}</p>
          <button onClick={() => disconnect()}>Disconnect</button>
        </>
      ) : (
        <button
          onClick={() => connect({ connector: mmConnector })}
          disabled={isLoading || !mmConnector}
        >
          {isLoading ? "Connecting..." : "Connect Wallet"}
        </button>
      )}
      {!mmConnector && (
        <p style={{ color: "red" }}>No wallet connector found.</p>
      )}
      {error && <p style={{ color: "red" }}>Error: {error.message}</p>}
    </div>
  );
}

function ContractActions() {
  // Check recipient registration
  const [checkRecipientAddress, setCheckRecipientAddress] = useState("");
  const [recipientOrgName, setRecipientOrgName] = useState("");
  const checkRecipient = async () => {
    setTxStatus("Checking recipient registration...");
    try {
      if (!window.ethereum) throw new Error("No wallet found");
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        provider
      );
      const orgName = await contract.getRecipientOrgName(checkRecipientAddress);
      setRecipientOrgName(orgName);
      setTxStatus(orgName ? `Registered: ${orgName}` : "Not registered");
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };

  // Check price feed status
  const [checkCurrencyCode, setCheckCurrencyCode] = useState("");
  const [priceFeedAddr, setPriceFeedAddr] = useState("");
  const checkPriceFeed = async () => {
    setTxStatus("Checking price feed...");
    try {
      if (!window.ethereum) throw new Error("No wallet found");
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        provider
      );
      const feedAddr = await contract.getPriceFeedAddress(checkCurrencyCode);
      setPriceFeedAddr(feedAddr);
      setTxStatus(
        feedAddr !== ethers.ZeroAddress
          ? `Price feed set: ${feedAddr}`
          : "No price feed set"
      );
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };
  const [recipientAddress, setRecipientAddress] = useState("");
  const [orgName, setOrgName] = useState("");
  const [donationAmount, setDonationAmount] = useState("");
  const [currencyCode, setCurrencyCode] = useState("");
  const [txStatus, setTxStatus] = useState("");

  // Connect to contract
  const getContract = async () => {
    if (!window.ethereum) return null;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    return new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  };

  // Register recipient
  const registerRecipient = async () => {
    setTxStatus("Registering recipient...");
    try {
      const contract = await getContract();
      const tx = await contract.registerRecipientWithOrg(
        recipientAddress,
        orgName
      );
      await tx.wait();
      setTxStatus("Recipient registered!");
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };

  // Remove recipient
  const removeRecipient = async () => {
    setTxStatus("Removing recipient...");
    try {
      const contract = await getContract();
      const tx = await contract.removeRecipientWithOrg(recipientAddress);
      await tx.wait();
      setTxStatus("Recipient removed!");
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };

  // Make donation
  const donate = async () => {
    setTxStatus("Sending donation...");
    try {
      const contract = await getContract();
      // Get latest price from contract (ETH per local currency)
      const priceRaw = await contract.getLatestPrice(currencyCode);
      // priceRaw is int256, may be negative, so use BigInt
      const price = BigInt(priceRaw);
      // Parse local currency amount to 18 decimals
      const localAmount = ethers.parseUnits(donationAmount, 18);
      // Calculate ETH to send: ETH = localAmount * price / 1e18
      // If price is ETH per local, this is correct. If price is local per ETH, you may need to invert.
      let ethValue;
      if (price > 0n) {
        ethValue = (localAmount * price) / 1000000000000000000n;
      } else {
        throw new Error("Invalid price feed value");
      }
      // Send donation with correct ETH value
      const tx = await contract.donationToRecipient(
        recipientAddress,
        currencyCode,
        localAmount,
        { value: ethValue }
      );
      await tx.wait();
      setTxStatus("Donation sent!");
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };

  return (
    <div
      style={{
        marginTop: "2rem",
        padding: "1rem",
        border: "1px solid #444",
        borderRadius: "8px",
      }}
    >
      <h2>Contract Actions</h2>
      <div>
        <h3>Register Recipient</h3>
        <input
          type="text"
          placeholder="Recipient Address"
          value={recipientAddress}
          onChange={(e) => setRecipientAddress(e.target.value)}
        />
        <input
          type="text"
          placeholder="Org Name"
          value={orgName}
          onChange={(e) => setOrgName(e.target.value)}
        />
        <button onClick={registerRecipient}>Register</button>
      </div>
      <div>
        <h3>Remove Recipient</h3>
        <input
          type="text"
          placeholder="Recipient Address"
          value={recipientAddress}
          onChange={(e) => setRecipientAddress(e.target.value)}
        />
        <button onClick={removeRecipient}>Remove</button>
      </div>
      <div>
        <h3>Make Donation</h3>
        <input
          type="text"
          placeholder="Recipient Address"
          value={recipientAddress}
          onChange={(e) => setRecipientAddress(e.target.value)}
        />
        <input
          type="text"
          placeholder="Currency Code (e.g. USD)"
          value={currencyCode}
          onChange={(e) => setCurrencyCode(e.target.value)}
        />
        <input
          type="text"
          placeholder="Amount"
          value={donationAmount}
          onChange={(e) => setDonationAmount(e.target.value)}
        />
        <button onClick={donate}>Donate</button>
      </div>
      <hr style={{ margin: "2em 0" }} />
      <div>
        <h3>Check Recipient Registration</h3>
        <input
          type="text"
          placeholder="Recipient Address"
          value={checkRecipientAddress}
          onChange={(e) => setCheckRecipientAddress(e.target.value)}
        />
        <button onClick={checkRecipient}>Check</button>
        {recipientOrgName && (
          <div style={{ marginTop: "0.5em", color: "#0a0" }}>
            Org Name: {recipientOrgName}
          </div>
        )}
      </div>
      <div>
        <h3>Check Price Feed Status</h3>
        <input
          type="text"
          placeholder="Currency Code (e.g. USD)"
          value={checkCurrencyCode}
          onChange={(e) => setCheckCurrencyCode(e.target.value)}
        />
        <button onClick={checkPriceFeed}>Check</button>
        {priceFeedAddr && (
          <div style={{ marginTop: "0.5em", color: "#0a0" }}>
            Price Feed Address: {priceFeedAddr}
          </div>
        )}
      </div>
      <div style={{ marginTop: "1rem", color: "#09f" }}>{txStatus}</div>
    </div>
  );
}

function PriceFeedActions() {
  const [currency, setCurrency] = useState("");
  const [priceFeedAddress, setPriceFeedAddress] = useState("");
  const [ethPerLocal, setEthPerLocal] = useState(false);
  const [txStatus, setTxStatus] = useState("");

  const getContract = async () => {
    if (!window.ethereum) return null;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    return new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  };

  const addPriceFeed = async () => {
    setTxStatus("Adding price feed...");
    try {
      const contract = await getContract();
      const tx = await contract.addPriceFeed(
        currency,
        priceFeedAddress,
        ethPerLocal
      );
      await tx.wait();
      setTxStatus("Price feed added!");
    } catch (err) {
      setTxStatus("Error: " + err.message);
    }
  };

  return (
    <div
      style={{
        marginTop: "2rem",
        padding: "1rem",
        border: "1px solid #444",
        borderRadius: "8px",
      }}
    >
      <h2>Price Feed Actions</h2>
      <div>
        <input
          type="text"
          placeholder="Currency Code (e.g. USD)"
          value={currency}
          onChange={(e) => setCurrency(e.target.value)}
        />
        <input
          type="text"
          placeholder="Price Feed Address"
          value={priceFeedAddress}
          onChange={(e) => setPriceFeedAddress(e.target.value)}
        />
        <label style={{ marginLeft: "1em" }}>
          <input
            type="checkbox"
            checked={ethPerLocal}
            onChange={(e) => setEthPerLocal(e.target.checked)}
          />{" "}
          ETH per Local
        </label>
        <button onClick={addPriceFeed}>Add Price Feed</button>
      </div>
      <div style={{ marginTop: "1rem", color: "#09f" }}>{txStatus}</div>
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
              <>
                <p>Integrate contract features below...</p>
                <PriceFeedActions />
                <ContractActions />
              </>
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
