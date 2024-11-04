-- Create Database
CREATE DATABASE RTOSystem;
USE RTOSystem;

-- Create Tables
CREATE TABLE Users (
    user_id VARCHAR(42) PRIMARY KEY,  -- Ethereum address
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    contact_number VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    residential_address TEXT,
    kyc_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE Dealers (
    dealer_id VARCHAR(42) PRIMARY KEY,  -- Ethereum address
    company_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    contact_person VARCHAR(100),
    contact_number VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    business_address TEXT,
    verification_status ENUM('PENDING', 'VERIFIED', 'REJECTED') DEFAULT 'PENDING',
    verification_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE Vehicles (
    number_plate VARCHAR(20) PRIMARY KEY,
    owner_id VARCHAR(42),
    vehicle_type VARCHAR(50),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    year_of_manufacture YEAR,
    engine_number VARCHAR(50) UNIQUE,
    chassis_number VARCHAR(50) UNIQUE,
    color VARCHAR(30),
    fuel_type VARCHAR(20),
    seating_capacity INT,
    registration_date TIMESTAMP,
    insurance_expiry DATE,
    registration_valid_until DATE,
    registration_status ENUM('ACTIVE', 'EXPIRED', 'SUSPENDED') DEFAULT 'ACTIVE',
    blockchain_tx_hash VARCHAR(66),  -- Ethereum transaction hash
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES Users(user_id)
);

CREATE TABLE Licenses (
    license_id VARCHAR(20) PRIMARY KEY,
    holder_id VARCHAR(42),
    license_type ENUM('LEARNER', 'PERMANENT', 'COMMERCIAL', 'HEAVY_VEHICLE'),
    issue_date TIMESTAMP,
    expiry_date TIMESTAMP,
    status ENUM('ACTIVE', 'EXPIRED', 'SUSPENDED', 'CANCELLED') DEFAULT 'ACTIVE',
    blood_group VARCHAR(5),
    medical_certificate_number VARCHAR(50),
    test_score INT,
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (holder_id) REFERENCES Users(user_id)
);

CREATE TABLE VehicleTransfers (
    transfer_id INT AUTO_INCREMENT PRIMARY KEY,
    number_plate VARCHAR(20),
    previous_owner_id VARCHAR(42),
    new_owner_id VARCHAR(42),
    transfer_date TIMESTAMP,
    transfer_price DECIMAL(12, 2),
    payment_method VARCHAR(50),
    transfer_status ENUM('PENDING', 'COMPLETED', 'REJECTED') DEFAULT 'PENDING',
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (number_plate) REFERENCES Vehicles(number_plate),
    FOREIGN KEY (previous_owner_id) REFERENCES Users(user_id),
    FOREIGN KEY (new_owner_id) REFERENCES Users(user_id)
);

CREATE TABLE Violations (
    violation_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_number VARCHAR(20),
    license_id VARCHAR(20),
    violation_type VARCHAR(100),
    violation_date TIMESTAMP,
    location VARCHAR(200),
    fine_amount DECIMAL(10, 2),
    payment_status ENUM('PENDING', 'PAID', 'DISPUTED') DEFAULT 'PENDING',
    officer_id VARCHAR(50),
    description TEXT,
    evidence_link TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_number) REFERENCES Vehicles(number_plate),
    FOREIGN KEY (license_id) REFERENCES Licenses(license_id)
);

CREATE TABLE Fees (
    fee_id INT AUTO_INCREMENT PRIMARY KEY,
    fee_type VARCHAR(50),
    amount DECIMAL(10, 2),
    effective_from DATE,
    effective_until DATE,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(42),
    payment_type VARCHAR(50),
    amount DECIMAL(10, 2),
    payment_date TIMESTAMP,
    payment_status ENUM('PENDING', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    transaction_reference VARCHAR(100),
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Create Indexes
CREATE INDEX idx_vehicle_owner ON Vehicles(owner_id);
CREATE INDEX idx_license_holder ON Licenses(holder_id);
CREATE INDEX idx_transfer_date ON VehicleTransfers(transfer_date);
CREATE INDEX idx_violation_date ON Violations(violation_date);
CREATE INDEX idx_payment_date ON Payments(payment_date);

-- Stored Procedures

-- Register New Vehicle
DELIMITER //
CREATE PROCEDURE RegisterVehicle(
    IN p_number_plate VARCHAR(20),
    IN p_owner_id VARCHAR(42),
    IN p_vehicle_type VARCHAR(50),
    IN p_manufacturer VARCHAR(100),
    IN p_model VARCHAR(100),
    IN p_year_of_manufacture YEAR,
    IN p_engine_number VARCHAR(50),
    IN p_chassis_number VARCHAR(50),
    IN p_blockchain_tx_hash VARCHAR(66)
)
BEGIN
    INSERT INTO Vehicles (
        number_plate, owner_id, vehicle_type, manufacturer, model,
        year_of_manufacture, engine_number, chassis_number, blockchain_tx_hash
    ) VALUES (
        p_number_plate, p_owner_id, p_vehicle_type, p_manufacturer, p_model,
        p_year_of_manufacture, p_engine_number, p_chassis_number, p_blockchain_tx_hash
    );
END //
DELIMITER ;

-- Issue New License
DELIMITER //
CREATE PROCEDURE IssueLicense(
    IN p_license_id VARCHAR(20),
    IN p_holder_id VARCHAR(42),
    IN p_license_type VARCHAR(20),
    IN p_expiry_date TIMESTAMP,
    IN p_blockchain_tx_hash VARCHAR(66)
)
BEGIN
    INSERT INTO Licenses (
        license_id, holder_id, license_type, issue_date, 
        expiry_date, blockchain_tx_hash
    ) VALUES (
        p_license_id, p_holder_id, p_license_type, CURRENT_TIMESTAMP,
        p_expiry_date, p_blockchain_tx_hash
    );
END //
DELIMITER ;

-- Record Vehicle Transfer
DELIMITER //
CREATE PROCEDURE RecordVehicleTransfer(
    IN p_number_plate VARCHAR(20),
    IN p_previous_owner_id VARCHAR(42),
    IN p_new_owner_id VARCHAR(42),
    IN p_transfer_price DECIMAL(12, 2),
    IN p_blockchain_tx_hash VARCHAR(66)
)
BEGIN
    START TRANSACTION;
    
    INSERT INTO VehicleTransfers (
        number_plate, previous_owner_id, new_owner_id,
        transfer_date, transfer_price, blockchain_tx_hash
    ) VALUES (
        p_number_plate, p_previous_owner_id, p_new_owner_id,
        CURRENT_TIMESTAMP, p_transfer_price, p_blockchain_tx_hash
    );
    
    UPDATE Vehicles
    SET owner_id = p_new_owner_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE number_plate = p_number_plate;
    
    COMMIT;
END //
DELIMITER ;

-- Get Vehicle History
DELIMITER //
CREATE PROCEDURE GetVehicleHistory(
    IN p_number_plate VARCHAR(20)
)
BEGIN
    SELECT 
        vt.transfer_date,
        u1.full_name AS previous_owner,
        u2.full_name AS new_owner,
        vt.transfer_price,
        vt.blockchain_tx_hash
    FROM VehicleTransfers vt
    JOIN Users u1 ON vt.previous_owner_id = u1.user_id
    JOIN Users u2 ON vt.new_owner_id = u2.user_id
    WHERE vt.number_plate = p_number_plate
    ORDER BY vt.transfer_date DESC;
END //
DELIMITER ;

-- Check License Status
DELIMITER //
CREATE PROCEDURE CheckLicenseStatus(
    IN p_license_id VARCHAR(20)
)
BEGIN
    SELECT 
        l.license_id,
        u.full_name AS holder_name,
        l.license_type,
        l.issue_date,
        l.expiry_date,
        l.status,
        CASE 
            WHEN l.expiry_date < CURRENT_TIMESTAMP THEN 'EXPIRED'
            ELSE 'VALID'
        END AS validity_status
    FROM Licenses l
    JOIN Users u ON l.holder_id = u.user_id
    WHERE l.license_id = p_license_id;
END //
DELIMITER ;

-- Record Violation
DELIMITER //
CREATE PROCEDURE RecordViolation(
    IN p_vehicle_number VARCHAR(20),
    IN p_license_id VARCHAR(20),
    IN p_violation_type VARCHAR(100),
    IN p_location VARCHAR(200),
    IN p_fine_amount DECIMAL(10, 2),
    IN p_officer_id VARCHAR(50),
    IN p_description TEXT
)
BEGIN
    INSERT INTO Violations (
        vehicle_number, license_id, violation_type,
        violation_date, location, fine_amount,
        officer_id, description
    ) VALUES (
        p_vehicle_number, p_license_id, p_violation_type,
        CURRENT_TIMESTAMP, p_location, p_fine_amount,
        p_officer_id, p_description
    );
END //
DELIMITER ;

-- Get Vehicle Details
DELIMITER //
CREATE PROCEDURE GetVehicleDetails(
    IN p_number_plate VARCHAR(20)
)
BEGIN
    SELECT 
        v.*,
        u.full_name AS owner_name,
        u.contact_number AS owner_contact,
        u.email AS owner_email
    FROM Vehicles v
    JOIN Users u ON v.owner_id = u.user_id
    WHERE v.number_plate = p_number_plate;
END //
DELIMITER ;