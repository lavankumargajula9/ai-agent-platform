-- AI Agent Platform: Healthcare Claims Database Schema
-- Medallion Architecture: Bronze (raw) → Silver (clean) → Gold (analytics)

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- REFERENCE TABLES
-- ============================================================

CREATE TABLE cpt_codes (
    cpt_code VARCHAR(10) PRIMARY KEY,
    description TEXT NOT NULL,
    category VARCHAR(100),
    avg_reimbursement NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE eligibility (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    payer_id VARCHAR(50) NOT NULL,
    plan_type VARCHAR(50),
    effective_date DATE NOT NULL,
    termination_date DATE,
    coverage_details JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_eligibility_patient ON eligibility(patient_id);
CREATE INDEX idx_eligibility_payer ON eligibility(payer_id);

-- ============================================================
-- BRONZE LAYER: Raw Claims (X12 837 format fields)
-- ============================================================

CREATE TABLE claims_raw (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    claim_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    provider_npi VARCHAR(15),
    cpt_code VARCHAR(10),
    diagnosis_code VARCHAR(15),
    service_date DATE,
    billed_amount NUMERIC(12, 2),
    payer_id VARCHAR(50),
    status VARCHAR(30) DEFAULT 'received',
    claim_type VARCHAR(20) DEFAULT 'professional',
    place_of_service VARCHAR(10),
    referring_provider_npi VARCHAR(15),
    authorization_number VARCHAR(50),
    raw_payload JSONB DEFAULT '{}',
    ingested_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_claims_raw_patient ON claims_raw(patient_id);
CREATE INDEX idx_claims_raw_payer ON claims_raw(payer_id);
CREATE INDEX idx_claims_raw_status ON claims_raw(status);
CREATE INDEX idx_claims_raw_date ON claims_raw(service_date);

-- ============================================================
-- SILVER LAYER: Validated & Normalized Claims
-- ============================================================

CREATE TABLE claims_clean (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    claim_id VARCHAR(50) UNIQUE NOT NULL REFERENCES claims_raw(claim_id),
    patient_id VARCHAR(50) NOT NULL,
    provider_npi VARCHAR(15),
    cpt_code VARCHAR(10),
    diagnosis_code VARCHAR(15),
    service_date DATE,
    billed_amount NUMERIC(12, 2),
    payer_id VARCHAR(50),
    is_valid BOOLEAN DEFAULT FALSE,
    validation_errors JSONB DEFAULT '[]',
    normalized_diagnosis VARCHAR(15),
    normalized_cpt VARCHAR(10),
    eligibility_status VARCHAR(30),
    risk_score NUMERIC(5, 2) DEFAULT 0.0,
    anomaly_flags JSONB DEFAULT '[]',
    processed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_claims_clean_valid ON claims_clean(is_valid);
CREATE INDEX idx_claims_clean_risk ON claims_clean(risk_score);

-- ============================================================
-- GOLD LAYER: Aggregated Analytics
-- ============================================================

CREATE TABLE claims_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    payer_id VARCHAR(50),
    total_claims INTEGER DEFAULT 0,
    approved_claims INTEGER DEFAULT 0,
    denied_claims INTEGER DEFAULT 0,
    denial_rate NUMERIC(5, 4) DEFAULT 0.0,
    total_billed NUMERIC(14, 2) DEFAULT 0.0,
    avg_billed NUMERIC(12, 2) DEFAULT 0.0,
    anomaly_count INTEGER DEFAULT 0,
    avg_processing_time_ms NUMERIC(10, 2) DEFAULT 0.0,
    computed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_period ON claims_analytics(period_start, period_end);
CREATE INDEX idx_analytics_payer ON claims_analytics(payer_id);

-- ============================================================
-- EVALUATION RESULTS
-- ============================================================

CREATE TABLE eval_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    eval_run_id VARCHAR(100) NOT NULL,
    test_case_id VARCHAR(100) NOT NULL,
    test_category VARCHAR(50),
    expected TEXT,
    actual TEXT,
    passed BOOLEAN,
    latency_ms NUMERIC(10, 2),
    token_cost NUMERIC(10, 4),
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_eval_run ON eval_results(eval_run_id);
CREATE INDEX idx_eval_category ON eval_results(test_category);

-- ============================================================
-- DATA LINEAGE TRACKING
-- ============================================================

CREATE TABLE data_lineage (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    target_id VARCHAR(100) NOT NULL,
    transform_name VARCHAR(100),
    transform_version VARCHAR(20),
    status VARCHAR(20) DEFAULT 'success',
    error_details TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_lineage_source ON data_lineage(source_table, source_id);
CREATE INDEX idx_lineage_target ON data_lineage(target_table, target_id);

-- ============================================================
-- SEED REFERENCE DATA
-- ============================================================

INSERT INTO cpt_codes (cpt_code, description, category, avg_reimbursement) VALUES
('99213', 'Office visit, established patient, low complexity', 'E&M', 92.00),
('99214', 'Office visit, established patient, moderate complexity', 'E&M', 130.00),
('99215', 'Office visit, established patient, high complexity', 'E&M', 175.00),
('99203', 'Office visit, new patient, low complexity', 'E&M', 110.00),
('99204', 'Office visit, new patient, moderate complexity', 'E&M', 170.00),
('99205', 'Office visit, new patient, high complexity', 'E&M', 225.00),
('99385', 'Preventive visit, new patient, 18-39', 'Preventive', 185.00),
('99395', 'Preventive visit, established patient, 18-39', 'Preventive', 160.00),
('99396', 'Preventive visit, established patient, 40-64', 'Preventive', 170.00),
('90834', 'Psychotherapy, 45 minutes', 'Behavioral Health', 105.00),
('90837', 'Psychotherapy, 60 minutes', 'Behavioral Health', 140.00),
('90847', 'Family psychotherapy with patient present', 'Behavioral Health', 130.00),
('71046', 'Chest X-ray, 2 views', 'Radiology', 45.00),
('71260', 'CT chest with contrast', 'Radiology', 350.00),
('73721', 'MRI lower extremity joint without contrast', 'Radiology', 425.00),
('80053', 'Comprehensive metabolic panel', 'Laboratory', 22.00),
('85025', 'Complete blood count (CBC)', 'Laboratory', 15.00),
('87804', 'Rapid influenza test', 'Laboratory', 25.00),
('87635', 'COVID-19 PCR test', 'Laboratory', 75.00),
('36415', 'Venipuncture', 'Procedures', 8.00),
('96372', 'Therapeutic injection, subcutaneous', 'Procedures', 35.00),
('20610', 'Joint injection, major joint', 'Procedures', 110.00),
('29881', 'Knee arthroscopy with meniscectomy', 'Surgery', 1850.00),
('27447', 'Total knee replacement', 'Surgery', 5500.00),
('43239', 'Upper GI endoscopy with biopsy', 'Surgery', 950.00);

INSERT INTO eligibility (patient_id, payer_id, plan_type, effective_date, termination_date, coverage_details) VALUES
('PAT001', 'PAYER_BCBS', 'PPO', '2024-01-01', NULL, '{"deductible": 1500, "copay": 25, "coinsurance": 0.20}'),
('PAT002', 'PAYER_AETNA', 'HMO', '2024-01-01', NULL, '{"deductible": 1000, "copay": 20, "coinsurance": 0.15}'),
('PAT003', 'PAYER_UNITED', 'PPO', '2024-01-01', '2025-06-30', '{"deductible": 2000, "copay": 30, "coinsurance": 0.25}'),
('PAT004', 'PAYER_CIGNA', 'EPO', '2024-03-01', NULL, '{"deductible": 1200, "copay": 25, "coinsurance": 0.20}'),
('PAT005', 'PAYER_BCBS', 'HMO', '2023-01-01', '2024-12-31', '{"deductible": 800, "copay": 15, "coinsurance": 0.10}'),
('PAT006', 'PAYER_HUMANA', 'PPO', '2024-06-01', NULL, '{"deductible": 1800, "copay": 35, "coinsurance": 0.25}'),
('PAT007', 'PAYER_AETNA', 'PPO', '2024-01-01', NULL, '{"deductible": 1500, "copay": 25, "coinsurance": 0.20}'),
('PAT008', 'PAYER_UNITED', 'HMO', '2024-01-01', NULL, '{"deductible": 500, "copay": 10, "coinsurance": 0.10}'),
('PAT009', 'PAYER_BCBS', 'PPO', '2023-07-01', '2024-06-30', '{"deductible": 2500, "copay": 40, "coinsurance": 0.30}'),
('PAT010', 'PAYER_CIGNA', 'HMO', '2024-01-01', NULL, '{"deductible": 750, "copay": 15, "coinsurance": 0.15}'),
('PAT011', 'PAYER_BCBS', 'PPO', '2024-01-01', NULL, '{"deductible": 1500, "copay": 25, "coinsurance": 0.20}'),
('PAT012', 'PAYER_AETNA', 'EPO', '2024-04-01', NULL, '{"deductible": 1000, "copay": 20, "coinsurance": 0.15}'),
('PAT013', 'PAYER_UNITED', 'PPO', '2025-01-01', NULL, '{"deductible": 2000, "copay": 30, "coinsurance": 0.25}'),
('PAT014', 'PAYER_HUMANA', 'HMO', '2024-01-01', '2025-03-31', '{"deductible": 600, "copay": 10, "coinsurance": 0.10}'),
('PAT015', 'PAYER_CIGNA', 'PPO', '2024-01-01', NULL, '{"deductible": 1500, "copay": 25, "coinsurance": 0.20}');
