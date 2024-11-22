# Patients–Clinical Trial Matching Management System

This repository contains a smart contract and a Gradio-based interface for managing clinical trials, including patient registration, eligibility evaluation, and approval workflows.

## Files

1. **Run_Gradio_interface_.ipynb**  
   A Jupyter Notebook implementing a Gradio interface to interact with the clinical trial smart contract. 

2. **Management.sol**  
   Solidity smart contract for managing clinical trials. Key features include:
   - Registration and approval workflows for trials and patients
   - Multi-step eligibility evaluation using multiple LLMs
   - Integration with IPFS for patient data storage

## Key Features

- **Gradio Interface**: Simplifies interaction with the smart contract.
- **Smart Contract Functionality**: Secure and decentralized management of clinical trials.
- **Decentralized Storage**: Utilizes IPFS for storing patient information securely.
- **Multi-LLM Voting System**: Ensures robust eligibility evaluation through majority voting.

## Prerequisites

### API Keys and Configuration
To use this system effectively, ensure the following keys and configurations are set up in your environment:

- **Infura/Alchemy Key**: For interacting with the Ethereum blockchain. Add this to your `.env` file or directly into the Notebook script.
- **Pinata/IPFS API Key and Secret**: For uploading and retrieving patient data securely from IPFS.
- **OpenAI API Key**: Required for using the OpenAI fine-tuned LLMs in the eligibility evaluation process. Set this in your environment file or the Notebook script as `OPENAI_API_KEY`.
- **Web3 Wallet Private Key**: For signing transactions with the smart contract. Ensure this is kept secure and never shared publicly.

### Setup
1. **Run the Gradio Interface**  
   Open the Jupyter Notebook (`Run_Gradio_interface_.ipynb`) and execute the cells to launch the Gradio interface.

2. **Deploy the Smart Contract**  
   Deploy the Solidity contract (`Management.sol`) to an Ethereum-compatible blockchain (e.g., Sepolia testnet).

3. **Connect to IPFS**  
   Ensure IPFS is set up and accessible for storing and retrieving patient data.

## License

This project is licensed under the MIT License.
