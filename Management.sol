// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ManagementContract {
    address public manager;  // This represents the sponsor/manager of the smart contract
    address public regulator;

    mapping(address => bool) public authorizedLLMs;
    mapping(address => bool) public registeredClinics;
    mapping(address => bool) public registeredEthicalTeam;

    //PatientEligibility
    struct Patient {
        uint256 patientId;
        address patientAddress;
        string condition;
        string ipfsHash;
        bool isEligible;
        bool clinicApproved;
        bool patientApproved;
        uint8 eligibilityCount; // Count of LLM approvals
        uint8 voteCount; // Count of total votes received
    }

    struct ClinicalTrial {
        uint256 trialId;
        string trialCriteria;
        address sponsor;
        bool isApproved;
        bool ethicalApproval;
    }

    mapping(uint256 => ClinicalTrial) public trials;
    mapping(uint256 => Patient) public patients; //For registration
    //[patientid][trialid] -> struct
    mapping(uint256 => mapping(uint256 => Patient)) public patientsTrial; //For trials

    uint256 public patientIdCounter;

    // Nested mapping to track whether an LLM has voted for a particular patient within a specific trial
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVotedForTrial;

    // Modifier to restrict access to the sponsor (manager)
    modifier onlySponsor() {
        require(msg.sender == manager, "Only the sponsor can perform this action");
        _;
    }

    // Modifier to restrict access to the regulator
    modifier onlyRegulator() {
        require(msg.sender == regulator, "Only the regulator can perform this action");
        _;
    }

    // Modifier to restrict access to authorized LLMs
    modifier onlyLLM() {
        require(authorizedLLMs[msg.sender], "Only authorized LLM can perform this action");
        _;
    }

    // Modifier to restrict access to the registered patient
    modifier onlyPatient(uint256 patientId) {
        require(patients[patientId].patientAddress == msg.sender, "Only the registered patient can perform this action");
        _;
    }

    // Modifier to restrict access to registered clinics
    modifier onlyClinic() {
        require(registeredClinics[msg.sender], "Only a registered clinic can perform this action");
        _;
    }

    // Modifier to restrict access to registered ethical team
    modifier onlyEthicalTeam() {
        require(registeredEthicalTeam[msg.sender], "Only a registered Ethical Team can perform this action");
        _;
    }

    // Events
    event TrialRegistered(uint256 indexed trialId, address sponsor);
    event TrialApproved(uint256 indexed trialId, address regulator);
    event EthicalApprovalGranted(uint256 indexed trialId);
    event PatientRegistered(uint256 indexed patientId, string condition, string ipfsHash);
    event ClinicRegistered(address indexed clinicAddress);
    event EthicalTeamRegistered(address indexed EthicalTeamAddress);
    event LLMRegistered(address indexed LLMAddress);
    event EligibilityEvaluated(uint256 indexed trialId, uint256 indexed patientId, bool isEligible, string model);
    event MajorityEligibilityDetermined(uint256 indexed trialId, uint256 indexed patientId, bool isEligible);
    event ClinicApprovalGranted(uint256 indexed patientId, uint256 indexed trialId, bool approved);
    event PatientApprovalGranted(uint256 indexed patientId, uint256 indexed trialId, bool approved);

    // Constructor to initialize manager and regulator
    constructor(address _regulator) {
        manager = msg.sender;
        regulator = _regulator;
    }

    function registerLLM(address LLMAddress) public onlyClinic {
        authorizedLLMs[LLMAddress] = true;
        emit LLMRegistered(LLMAddress);
    }
    
    function registerET(address EthicalTeamAddress) public onlyRegulator {
        registeredEthicalTeam[EthicalTeamAddress] = true;
        emit EthicalTeamRegistered(EthicalTeamAddress);
    }

    function registerClinic(address clinicAddress) public onlySponsor {
        registeredClinics[clinicAddress] = true;
        emit ClinicRegistered(clinicAddress);
    }

    function registerTrial(uint256 trialId, string memory trialCriteria) public onlySponsor {
        trials[trialId] = ClinicalTrial({
            trialId: trialId,
            trialCriteria: trialCriteria,
            sponsor: msg.sender,
            isApproved: false,
            ethicalApproval: false
        });
        emit TrialRegistered(trialId, msg.sender);
    }

    function approveTrial(uint256 trialId) public onlyRegulator {
        ClinicalTrial storage trial = trials[trialId];
        require(trial.sponsor != address(0), "Trial does not exist");
        trial.isApproved = true;
        emit TrialApproved(trialId, msg.sender);
    }

    function grantEthicalApproval(uint256 trialId) public onlyEthicalTeam {
        ClinicalTrial storage trial = trials[trialId];
        require(trial.isApproved, "Trial not approved by the regulator");
        trial.ethicalApproval = true;
        emit EthicalApprovalGranted(trialId);
    }

    function registerPatient(string memory condition, string memory ipfsHash) public onlyClinic {
        uint256 patientId = patientIdCounter;
        patientIdCounter++;

        patients[patientId].patientId = patientId;
        patients[patientId].patientAddress = msg.sender;
        patients[patientId].condition = condition;
        patients[patientId].ipfsHash = ipfsHash;
        patients[patientId].isEligible = false;
        patients[patientId].clinicApproved = false;
        patients[patientId].patientApproved = false;
        patients[patientId].eligibilityCount = 0;
        patients[patientId].voteCount = 0;

        emit PatientRegistered(patientId, condition, ipfsHash);
    }

    // Record LLM eligibility evaluation (only authorized LLM)
    function evaluateEligibility(uint256 trialId, uint256 patientId, bool isEligible, string memory model) public onlyLLM {
        ClinicalTrial storage trial = trials[trialId];
        require(trial.isApproved, "Trial must be approved before eligibility evaluation"); // Ensure trial is approved
        Patient storage patient = patients[patientId];
        require(bytes(patient.ipfsHash).length > 0, "Patient not registered");

        // Ensure each LLM can only vote once for each patient in each trial
        require(!hasVotedForTrial[trialId][patientId][msg.sender], "LLM has already voted for this patient for the given trial");

        // Mark that the LLM has voted for this patient in this trial
        hasVotedForTrial[trialId][patientId][msg.sender] = true;

        // Increment vote count
        patientsTrial[patientId][trialId].voteCount++;

        // Increment eligibility count if eligible
        if (isEligible) {
            patientsTrial[patientId][trialId].eligibilityCount++;
        }

        // Emit event after each eligibility evaluation
        emit EligibilityEvaluated(trialId, patientId, isEligible, model);

        // Determine majority eligibility after all votes are in
        if (patientsTrial[patientId][trialId].voteCount == 3) { // Assuming 3 LLMs are used to evaluate eligibility
            if (patientsTrial[patientId][trialId].eligibilityCount >= 2) {
                patientsTrial[patientId][trialId].isEligible = true;
                emit MajorityEligibilityDetermined(trialId, patientId, patientsTrial[patientId][trialId].isEligible);
            } else {
                patientsTrial[patientId][trialId].isEligible = false;
                emit MajorityEligibilityDetermined(trialId, patientId, patientsTrial[patientId][trialId].isEligible);
            }
        }
    }

    function clinicApproval(uint256 patientId, uint256 trialId, bool approved) public onlyClinic {
        require(patientsTrial[patientId][trialId].isEligible, "Patient is not eligible");
        patientsTrial[patientId][trialId].clinicApproved = approved;
        emit ClinicApprovalGranted(patientId, trialId, approved);
    }

    function patientApproval(uint256 patientId, uint256 trialId, bool approved) public onlyPatient(patientId) {
        require(patientsTrial[patientId][trialId].isEligible, "Patient is not eligible");
        patientsTrial[patientId][trialId].patientApproved = approved;
        emit PatientApprovalGranted(patientId, trialId, approved);
    }
}
