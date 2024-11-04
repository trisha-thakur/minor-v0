// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Main RTO contract to manage vehicle registrations and licenses
contract RTOSystem {
    address public admin;
    uint256 public registrationFee;
    uint256 public licenseFee;
    
    struct Vehicle {
        string numberPlate;
        address owner;
        string vehicleType;
        string manufacturer;
        uint256 registrationDate;
        bool isValid;
    }
    
    struct License {
        address holder;
        string licenseType;
        uint256 issueDate;
        uint256 expiryDate;
        bool isValid;
    }
    
    mapping(string => Vehicle) public vehicles;
    mapping(address => License) public licenses;
    mapping(address => bool) public verifiedDealers;
    
    event VehicleRegistered(string numberPlate, address owner);
    event LicenseIssued(address holder, string licenseType);
    event DealerVerified(address dealer);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyVerifiedDealer() {
        require(verifiedDealers[msg.sender], "Only verified dealers can perform this action");
        _;
    }
    
    constructor(uint256 _registrationFee, uint256 _licenseFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
        licenseFee = _licenseFee;
    }
    
    function registerVehicle(
        string memory _numberPlate,
        string memory _vehicleType,
        string memory _manufacturer
    ) public payable {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!vehicles[_numberPlate].isValid, "Vehicle already registered");
        
        vehicles[_numberPlate] = Vehicle({
            numberPlate: _numberPlate,
            owner: msg.sender,
            vehicleType: _vehicleType,
            manufacturer: _manufacturer,
            registrationDate: block.timestamp,
            isValid: true
        });
        
        emit VehicleRegistered(_numberPlate, msg.sender);
    }
    
    function issueLicense(
        address _holder,
        string memory _licenseType,
        uint256 _validityYears
    ) public payable {
        require(msg.value >= licenseFee, "Insufficient license fee");
        require(!licenses[_holder].isValid, "License already exists");
        
        licenses[_holder] = License({
            holder: _holder,
            licenseType: _licenseType,
            issueDate: block.timestamp,
            expiryDate: block.timestamp + (_validityYears * 365 days),
            isValid: true
        });
        
        emit LicenseIssued(_holder, _licenseType);
    }
    
    function verifyDealer(address _dealer) public onlyAdmin {
        verifiedDealers[_dealer] = true;
        emit DealerVerified(_dealer);
    }
    
    function transferVehicle(string memory _numberPlate, address _newOwner) public {
        require(vehicles[_numberPlate].owner == msg.sender, "Not the vehicle owner");
        require(vehicles[_numberPlate].isValid, "Vehicle not registered");
        
        vehicles[_numberPlate].owner = _newOwner;
    }
    
    function checkLicenseValidity(address _holder) public view returns (bool, uint256) {
        License memory license = licenses[_holder];
        return (license.isValid && block.timestamp <= license.expiryDate, license.expiryDate);
    }
    
    function checkVehicleDetails(string memory _numberPlate) public view returns (
        address owner,
        string memory vehicleType,
        string memory manufacturer,
        uint256 registrationDate,
        bool isValid
    ) {
        Vehicle memory vehicle = vehicles[_numberPlate];
        return (
            vehicle.owner,
            vehicle.vehicleType,
            vehicle.manufacturer,
            vehicle.registrationDate,
            vehicle.isValid
        );
    }
    
    function updateRegistrationFee(uint256 _newFee) public onlyAdmin {
        registrationFee = _newFee;
    }
    
    function updateLicenseFee(uint256 _newFee) public onlyAdmin {
        licenseFee = _newFee;
    }
    
    function withdrawFunds() public onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
}

// Contract to handle vehicle transfers and ownership history
contract VehicleTransferSystem {
    RTOSystem public rtoSystem;
    
    struct TransferRecord {
        address previousOwner;
        address newOwner;
        uint256 transferDate;
        uint256 transferPrice;
    }
    
    mapping(string => TransferRecord[]) public transferHistory;
    
    event VehicleTransferred(
        string numberPlate,
        address previousOwner,
        address newOwner,
        uint256 transferPrice
    );
    
    constructor(address _rtoSystem) {
        rtoSystem = RTOSystem(_rtoSystem);
    }
    
    function recordTransfer(
        string memory _numberPlate,
        address _newOwner,
        uint256 _transferPrice
    ) public {
        (address currentOwner,,,,bool isValid) = rtoSystem.checkVehicleDetails(_numberPlate);
        require(isValid, "Vehicle not registered");
        require(currentOwner == msg.sender, "Not the vehicle owner");
        
        transferHistory[_numberPlate].push(TransferRecord({
            previousOwner: msg.sender,
            newOwner: _newOwner,
            transferDate: block.timestamp,
            transferPrice: _transferPrice
        }));
        
        rtoSystem.transferVehicle(_numberPlate, _newOwner);
        
        emit VehicleTransferred(_numberPlate, msg.sender, _newOwner, _transferPrice);
    }
    
    function getTransferHistory(string memory _numberPlate) public view returns (
        address[] memory previousOwners,
        address[] memory newOwners,
        uint256[] memory transferDates,
        uint256[] memory transferPrices
    ) {
        TransferRecord[] memory history = transferHistory[_numberPlate];
        uint256 length = history.length;
        
        previousOwners = new address[](length);
        newOwners = new address[](length);
        transferDates = new uint256[](length);
        transferPrices = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            previousOwners[i] = history[i].previousOwner;
            newOwners[i] = history[i].newOwner;
            transferDates[i] = history[i].transferDate;
            transferPrices[i] = history[i].transferPrice;
        }
        
        return (previousOwners, newOwners, transferDates, transferPrices);
    }
}