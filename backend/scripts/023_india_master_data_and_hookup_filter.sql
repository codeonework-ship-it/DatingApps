-- India master data + hookup-only preference support
-- Run after 022_expand_profile_filter_dimensions.sql

ALTER TABLE matching.user_profile_tag_filters
  ADD COLUMN IF NOT EXISTS hookup_only BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_hookup_only
  ON matching.user_profile_tag_filters(hookup_only);

CREATE TABLE IF NOT EXISTS matching.master_countries (
  id BIGSERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT UNIQUE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_states (
  id BIGSERIAL PRIMARY KEY,
  country_code TEXT NOT NULL REFERENCES matching.master_countries(code) ON DELETE CASCADE,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  is_union_territory BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(country_code, name)
);

CREATE TABLE IF NOT EXISTS matching.master_cities (
  id BIGSERIAL PRIMARY KEY,
  state_code TEXT NOT NULL REFERENCES matching.master_states(code) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(state_code, name)
);

CREATE TABLE IF NOT EXISTS matching.master_religions (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_mother_tongues (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_master_states_country ON matching.master_states(country_code, name);
CREATE INDEX IF NOT EXISTS idx_master_cities_state ON matching.master_cities(state_code, name);

INSERT INTO matching.master_countries (code, name)
VALUES ('IN', 'India')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO matching.master_states (country_code, code, name, is_union_territory) VALUES
('IN', 'IN-AP', 'Andhra Pradesh', FALSE),
('IN', 'IN-AR', 'Arunachal Pradesh', FALSE),
('IN', 'IN-AS', 'Assam', FALSE),
('IN', 'IN-BR', 'Bihar', FALSE),
('IN', 'IN-CT', 'Chhattisgarh', FALSE),
('IN', 'IN-GA', 'Goa', FALSE),
('IN', 'IN-GJ', 'Gujarat', FALSE),
('IN', 'IN-HR', 'Haryana', FALSE),
('IN', 'IN-HP', 'Himachal Pradesh', FALSE),
('IN', 'IN-JH', 'Jharkhand', FALSE),
('IN', 'IN-KA', 'Karnataka', FALSE),
('IN', 'IN-KL', 'Kerala', FALSE),
('IN', 'IN-MP', 'Madhya Pradesh', FALSE),
('IN', 'IN-MH', 'Maharashtra', FALSE),
('IN', 'IN-MN', 'Manipur', FALSE),
('IN', 'IN-ML', 'Meghalaya', FALSE),
('IN', 'IN-MZ', 'Mizoram', FALSE),
('IN', 'IN-NL', 'Nagaland', FALSE),
('IN', 'IN-OR', 'Odisha', FALSE),
('IN', 'IN-PB', 'Punjab', FALSE),
('IN', 'IN-RJ', 'Rajasthan', FALSE),
('IN', 'IN-SK', 'Sikkim', FALSE),
('IN', 'IN-TN', 'Tamil Nadu', FALSE),
('IN', 'IN-TG', 'Telangana', FALSE),
('IN', 'IN-TR', 'Tripura', FALSE),
('IN', 'IN-UP', 'Uttar Pradesh', FALSE),
('IN', 'IN-UT', 'Uttarakhand', FALSE),
('IN', 'IN-WB', 'West Bengal', FALSE),
('IN', 'IN-AN', 'Andaman and Nicobar Islands', TRUE),
('IN', 'IN-CH', 'Chandigarh', TRUE),
('IN', 'IN-DN', 'Dadra and Nagar Haveli and Daman and Diu', TRUE),
('IN', 'IN-DL', 'Delhi', TRUE),
('IN', 'IN-JK', 'Jammu and Kashmir', TRUE),
('IN', 'IN-LA', 'Ladakh', TRUE),
('IN', 'IN-LD', 'Lakshadweep', TRUE),
('IN', 'IN-PY', 'Puducherry', TRUE)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  country_code = EXCLUDED.country_code,
  is_union_territory = EXCLUDED.is_union_territory;

INSERT INTO matching.master_cities (state_code, name) VALUES
('IN-AP', 'Visakhapatnam'), ('IN-AP', 'Vijayawada'), ('IN-AP', 'Guntur'),
('IN-AR', 'Itanagar'), ('IN-AR', 'Naharlagun'), ('IN-AR', 'Pasighat'),
('IN-AS', 'Guwahati'), ('IN-AS', 'Silchar'), ('IN-AS', 'Dibrugarh'),
('IN-BR', 'Patna'), ('IN-BR', 'Gaya'), ('IN-BR', 'Muzaffarpur'),
('IN-CT', 'Raipur'), ('IN-CT', 'Bhilai'), ('IN-CT', 'Bilaspur'),
('IN-GA', 'Panaji'), ('IN-GA', 'Margao'), ('IN-GA', 'Vasco da Gama'),
('IN-GJ', 'Ahmedabad'), ('IN-GJ', 'Surat'), ('IN-GJ', 'Vadodara'),
('IN-HR', 'Gurugram'), ('IN-HR', 'Faridabad'), ('IN-HR', 'Panipat'),
('IN-HP', 'Shimla'), ('IN-HP', 'Dharamshala'), ('IN-HP', 'Solan'),
('IN-JH', 'Ranchi'), ('IN-JH', 'Jamshedpur'), ('IN-JH', 'Dhanbad'),
('IN-KA', 'Bengaluru'), ('IN-KA', 'Mysuru'), ('IN-KA', 'Mangaluru'),
('IN-KL', 'Thiruvananthapuram'), ('IN-KL', 'Kochi'), ('IN-KL', 'Kozhikode'),
('IN-MP', 'Indore'), ('IN-MP', 'Bhopal'), ('IN-MP', 'Jabalpur'),
('IN-MH', 'Mumbai'), ('IN-MH', 'Pune'), ('IN-MH', 'Nagpur'),
('IN-MN', 'Imphal'), ('IN-MN', 'Thoubal'), ('IN-MN', 'Bishnupur'),
('IN-ML', 'Shillong'), ('IN-ML', 'Tura'), ('IN-ML', 'Jowai'),
('IN-MZ', 'Aizawl'), ('IN-MZ', 'Lunglei'), ('IN-MZ', 'Champhai'),
('IN-NL', 'Kohima'), ('IN-NL', 'Dimapur'), ('IN-NL', 'Mokokchung'),
('IN-OR', 'Bhubaneswar'), ('IN-OR', 'Cuttack'), ('IN-OR', 'Rourkela'),
('IN-PB', 'Ludhiana'), ('IN-PB', 'Amritsar'), ('IN-PB', 'Jalandhar'),
('IN-RJ', 'Jaipur'), ('IN-RJ', 'Jodhpur'), ('IN-RJ', 'Udaipur'),
('IN-SK', 'Gangtok'), ('IN-SK', 'Namchi'), ('IN-SK', 'Gyalshing'),
('IN-TN', 'Chennai'), ('IN-TN', 'Coimbatore'), ('IN-TN', 'Madurai'),
('IN-TG', 'Hyderabad'), ('IN-TG', 'Warangal'), ('IN-TG', 'Nizamabad'),
('IN-TR', 'Agartala'), ('IN-TR', 'Udaipur'), ('IN-TR', 'Dharmanagar'),
('IN-UP', 'Lucknow'), ('IN-UP', 'Kanpur'), ('IN-UP', 'Varanasi'),
('IN-UT', 'Dehradun'), ('IN-UT', 'Haridwar'), ('IN-UT', 'Haldwani'),
('IN-WB', 'Kolkata'), ('IN-WB', 'Howrah'), ('IN-WB', 'Siliguri'),
('IN-AN', 'Port Blair'),
('IN-CH', 'Chandigarh'),
('IN-DN', 'Daman'), ('IN-DN', 'Silvassa'),
('IN-DL', 'New Delhi'), ('IN-DL', 'Delhi'),
('IN-JK', 'Srinagar'), ('IN-JK', 'Jammu'),
('IN-LA', 'Leh'), ('IN-LA', 'Kargil'),
('IN-LD', 'Kavaratti'),
('IN-PY', 'Puducherry'), ('IN-PY', 'Karaikal')
ON CONFLICT (state_code, name) DO NOTHING;

INSERT INTO matching.master_religions (name, sort_order) VALUES
('Hindu', 10),
('Muslim', 20),
('Christian', 30),
('Sikh', 40),
('Buddhist', 50),
('Jain', 60),
('Parsi', 70),
('Jewish', 80),
('Bahai', 90),
('Tribal / Indigenous', 100),
('Spiritual', 110),
('Other', 120),
('Prefer not to say', 130)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_mother_tongues (name, sort_order) VALUES
('Assamese', 10),
('Bengali', 20),
('Bodo', 30),
('Dogri', 40),
('English', 50),
('Gujarati', 60),
('Hindi', 70),
('Kannada', 80),
('Kashmiri', 90),
('Konkani', 100),
('Maithili', 110),
('Malayalam', 120),
('Manipuri', 130),
('Marathi', 140),
('Nepali', 150),
('Odia', 160),
('Punjabi', 170),
('Sanskrit', 180),
('Santali', 190),
('Sindhi', 200),
('Tamil', 210),
('Telugu', 220),
('Urdu', 230)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;
