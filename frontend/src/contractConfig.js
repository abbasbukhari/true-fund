// This file will hold the contract ABI and address for frontend integration
export const CONTRACT_ADDRESS = ""; // TODO: Replace with your deployed contract address
export const CONTRACT_ABI = [
  { type: "constructor", inputs: [], stateMutability: "nonpayable" },
  {
    type: "function",
    name: "MINIMUM_USD",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "addPriceFeed",
    inputs: [
      { name: "currency", type: "string", internalType: "string" },
      { name: "priceFeedAddress", type: "address", internalType: "address" },
      { name: "ethPerLocal", type: "bool", internalType: "bool" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "donationToRecipient",
    inputs: [
      { name: "recipientAddress", type: "address", internalType: "address" },
      { name: "currencyCode", type: "string", internalType: "string" },
      {
        name: "amountInLocalCurrency",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "getLatestPrice",
    inputs: [{ name: "currencyCode", type: "string", internalType: "string" }],
    outputs: [{ name: "", type: "int256", internalType: "int256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getPriceFeedAddress",
    inputs: [{ name: "currencyCode", type: "string", internalType: "string" }],
    outputs: [
      { name: "feedAddress", type: "address", internalType: "address" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRecipientOrgName",
    inputs: [
      { name: "recipientAddress", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "orgName", type: "string", internalType: "string" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isEthPerLocal",
    inputs: [{ name: "", type: "string", internalType: "string" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "priceFeeds",
    inputs: [{ name: "", type: "string", internalType: "string" }],
    outputs: [{ name: "", type: "address", internalType: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "recipientsAddressToOrgName",
    inputs: [{ name: "", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "string", internalType: "string" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "refund",
    inputs: [{ name: "", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "registerRecipientWithOrg",
    inputs: [
      { name: "recipientAddress", type: "address", internalType: "address" },
      { name: "recipientOrgName", type: "string", internalType: "string" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removePriceFeed",
    inputs: [{ name: "currency", type: "string", internalType: "string" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeRecipientWithOrg",
    inputs: [
      { name: "recipientAddress", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "sweep",
    inputs: [{ name: "to", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferAdmin",
    inputs: [{ name: "newAdmin", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "DonationMade",
    inputs: [
      {
        name: "donor",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "recipient",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "currency",
        type: "string",
        indexed: false,
        internalType: "string",
      },
      {
        name: "localAmount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "ethAmount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "usdAmount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "PriceFeedAdded",
    inputs: [
      {
        name: "currency",
        type: "string",
        indexed: false,
        internalType: "string",
      },
      {
        name: "priceFeedAddress",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "isEthPerLocal",
        type: "bool",
        indexed: false,
        internalType: "bool",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "PriceFeedRemoved",
    inputs: [
      {
        name: "currency",
        type: "string",
        indexed: false,
        internalType: "string",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RecipientRemoved",
    inputs: [
      {
        name: "recipientAddress",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
];
