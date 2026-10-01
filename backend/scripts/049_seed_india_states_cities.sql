-- Comprehensive India states/UTs and city master-data seed.
-- Run after 023_india_master_data_and_hookup_filter.sql and 030_public_master_data_views.sql.
-- Storage tables: matching.master_countries, matching.master_states, matching.master_cities.
-- Idempotency: natural-key upserts on country code, state code, and (state_code, city name).
-- Retry/recovery: safe to re-run; existing rows are reactivated without deleting custom rows.

BEGIN;

CREATE SCHEMA IF NOT EXISTS matching;

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

CREATE TABLE IF NOT EXISTS matching.master_languages (
	id BIGSERIAL PRIMARY KEY,
	code TEXT UNIQUE,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_workout_frequencies (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_diet_preferences (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_diet_types (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_sleep_schedules (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_travel_styles (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_political_comfort_ranges (
	id BIGSERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	sort_order INTEGER NOT NULL DEFAULT 0,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_master_states_country ON matching.master_states(country_code, name);
CREATE INDEX IF NOT EXISTS idx_master_cities_state ON matching.master_cities(state_code, name);

INSERT INTO matching.master_countries (code, name, is_active)
VALUES ('IN', 'India', TRUE)
ON CONFLICT (code) DO UPDATE SET
	name = EXCLUDED.name,
	is_active = TRUE;

WITH states(country_code, code, name, is_union_territory) AS (
	VALUES
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
)
INSERT INTO matching.master_states (country_code, code, name, is_union_territory, is_active)
SELECT country_code, code, name, is_union_territory, TRUE
FROM states
ON CONFLICT (code) DO UPDATE SET
	country_code = EXCLUDED.country_code,
	name = EXCLUDED.name,
	is_union_territory = EXCLUDED.is_union_territory,
	is_active = TRUE;

WITH cities(state_code, name) AS (
	VALUES
		('IN-AP', 'Adoni'), ('IN-AP', 'Amaravati'), ('IN-AP', 'Anantapur'), ('IN-AP', 'Bhimavaram'), ('IN-AP', 'Chilakaluripet'), ('IN-AP', 'Chittoor'), ('IN-AP', 'Dharmavaram'), ('IN-AP', 'Eluru'), ('IN-AP', 'Gudur'), ('IN-AP', 'Guntakal'), ('IN-AP', 'Guntur'), ('IN-AP', 'Hindupur'), ('IN-AP', 'Kadapa'), ('IN-AP', 'Kakinada'), ('IN-AP', 'Kurnool'), ('IN-AP', 'Machilipatnam'), ('IN-AP', 'Madanapalle'), ('IN-AP', 'Nandyal'), ('IN-AP', 'Narasaraopet'), ('IN-AP', 'Nellore'), ('IN-AP', 'Ongole'), ('IN-AP', 'Proddatur'), ('IN-AP', 'Rajahmundry'), ('IN-AP', 'Srikakulam'), ('IN-AP', 'Tadepalligudem'), ('IN-AP', 'Tadipatri'), ('IN-AP', 'Tenali'), ('IN-AP', 'Tirupati'), ('IN-AP', 'Vijayawada'), ('IN-AP', 'Visakhapatnam'), ('IN-AP', 'Vizianagaram'),
		('IN-AR', 'Aalo'), ('IN-AR', 'Anini'), ('IN-AR', 'Bomdila'), ('IN-AR', 'Changlang'), ('IN-AR', 'Itanagar'), ('IN-AR', 'Khonsa'), ('IN-AR', 'Longding'), ('IN-AR', 'Naharlagun'), ('IN-AR', 'Namsai'), ('IN-AR', 'Pasighat'), ('IN-AR', 'Roing'), ('IN-AR', 'Tawang'), ('IN-AR', 'Tezu'), ('IN-AR', 'Yingkiong'), ('IN-AR', 'Ziro'),
		('IN-AS', 'Barpeta'), ('IN-AS', 'Bongaigaon'), ('IN-AS', 'Dhubri'), ('IN-AS', 'Dibrugarh'), ('IN-AS', 'Diphu'), ('IN-AS', 'Goalpara'), ('IN-AS', 'Golaghat'), ('IN-AS', 'Guwahati'), ('IN-AS', 'Haflong'), ('IN-AS', 'Hailakandi'), ('IN-AS', 'Jorhat'), ('IN-AS', 'Karimganj'), ('IN-AS', 'Kokrajhar'), ('IN-AS', 'Lakhimpur'), ('IN-AS', 'Mangaldoi'), ('IN-AS', 'Nagaon'), ('IN-AS', 'Nalbari'), ('IN-AS', 'Sivasagar'), ('IN-AS', 'Silchar'), ('IN-AS', 'Tezpur'), ('IN-AS', 'Tinsukia'),
		('IN-BR', 'Arrah'), ('IN-BR', 'Aurangabad'), ('IN-BR', 'Bagaha'), ('IN-BR', 'Begusarai'), ('IN-BR', 'Bettiah'), ('IN-BR', 'Bhagalpur'), ('IN-BR', 'Bihar Sharif'), ('IN-BR', 'Buxar'), ('IN-BR', 'Chhapra'), ('IN-BR', 'Darbhanga'), ('IN-BR', 'Dehri'), ('IN-BR', 'Gaya'), ('IN-BR', 'Hajipur'), ('IN-BR', 'Jamui'), ('IN-BR', 'Jehanabad'), ('IN-BR', 'Katihar'), ('IN-BR', 'Kishanganj'), ('IN-BR', 'Motihari'), ('IN-BR', 'Munger'), ('IN-BR', 'Muzaffarpur'), ('IN-BR', 'Patna'), ('IN-BR', 'Purnia'), ('IN-BR', 'Saharsa'), ('IN-BR', 'Samastipur'), ('IN-BR', 'Sasaram'), ('IN-BR', 'Sitamarhi'), ('IN-BR', 'Siwan'),
		('IN-CT', 'Ambikapur'), ('IN-CT', 'Bhilai'), ('IN-CT', 'Bilaspur'), ('IN-CT', 'Dhamtari'), ('IN-CT', 'Durg'), ('IN-CT', 'Jagdalpur'), ('IN-CT', 'Korba'), ('IN-CT', 'Mahasamund'), ('IN-CT', 'Raigarh'), ('IN-CT', 'Raipur'), ('IN-CT', 'Rajnandgaon'),
		('IN-GA', 'Bicholim'), ('IN-GA', 'Canacona'), ('IN-GA', 'Mapusa'), ('IN-GA', 'Margao'), ('IN-GA', 'Mormugao'), ('IN-GA', 'Panaji'), ('IN-GA', 'Ponda'), ('IN-GA', 'Vasco da Gama'),
		('IN-GJ', 'Ahmedabad'), ('IN-GJ', 'Amreli'), ('IN-GJ', 'Anand'), ('IN-GJ', 'Bharuch'), ('IN-GJ', 'Bhavnagar'), ('IN-GJ', 'Bhuj'), ('IN-GJ', 'Botad'), ('IN-GJ', 'Dahod'), ('IN-GJ', 'Gandhidham'), ('IN-GJ', 'Gandhinagar'), ('IN-GJ', 'Godhra'), ('IN-GJ', 'Jamnagar'), ('IN-GJ', 'Junagadh'), ('IN-GJ', 'Mehsana'), ('IN-GJ', 'Morbi'), ('IN-GJ', 'Nadiad'), ('IN-GJ', 'Navsari'), ('IN-GJ', 'Palanpur'), ('IN-GJ', 'Patan'), ('IN-GJ', 'Porbandar'), ('IN-GJ', 'Rajkot'), ('IN-GJ', 'Surat'), ('IN-GJ', 'Surendranagar'), ('IN-GJ', 'Vadodara'), ('IN-GJ', 'Valsad'), ('IN-GJ', 'Vapi'), ('IN-GJ', 'Veraval'),
		('IN-HR', 'Ambala'), ('IN-HR', 'Bahadurgarh'), ('IN-HR', 'Bhiwani'), ('IN-HR', 'Faridabad'), ('IN-HR', 'Fatehabad'), ('IN-HR', 'Gurugram'), ('IN-HR', 'Hisar'), ('IN-HR', 'Jind'), ('IN-HR', 'Kaithal'), ('IN-HR', 'Karnal'), ('IN-HR', 'Kurukshetra'), ('IN-HR', 'Narnaul'), ('IN-HR', 'Palwal'), ('IN-HR', 'Panchkula'), ('IN-HR', 'Panipat'), ('IN-HR', 'Rewari'), ('IN-HR', 'Rohtak'), ('IN-HR', 'Sirsa'), ('IN-HR', 'Sonipat'), ('IN-HR', 'Yamunanagar'),
		('IN-HP', 'Bilaspur'), ('IN-HP', 'Chamba'), ('IN-HP', 'Dharamshala'), ('IN-HP', 'Hamirpur'), ('IN-HP', 'Kangra'), ('IN-HP', 'Kullu'), ('IN-HP', 'Mandi'), ('IN-HP', 'Nahan'), ('IN-HP', 'Palampur'), ('IN-HP', 'Shimla'), ('IN-HP', 'Solan'), ('IN-HP', 'Una'),
		('IN-JH', 'Bokaro Steel City'), ('IN-JH', 'Chaibasa'), ('IN-JH', 'Deoghar'), ('IN-JH', 'Dhanbad'), ('IN-JH', 'Dumka'), ('IN-JH', 'Giridih'), ('IN-JH', 'Hazaribagh'), ('IN-JH', 'Jamshedpur'), ('IN-JH', 'Medininagar'), ('IN-JH', 'Phusro'), ('IN-JH', 'Ramgarh'), ('IN-JH', 'Ranchi'),
		('IN-KA', 'Bagalkot'), ('IN-KA', 'Ballari'), ('IN-KA', 'Belagavi'), ('IN-KA', 'Bengaluru'), ('IN-KA', 'Bidar'), ('IN-KA', 'Chikkamagaluru'), ('IN-KA', 'Chitradurga'), ('IN-KA', 'Davanagere'), ('IN-KA', 'Dharwad'), ('IN-KA', 'Gadag'), ('IN-KA', 'Hassan'), ('IN-KA', 'Hubballi'), ('IN-KA', 'Kalaburagi'), ('IN-KA', 'Karwar'), ('IN-KA', 'Kolar'), ('IN-KA', 'Koppal'), ('IN-KA', 'Madikeri'), ('IN-KA', 'Mandya'), ('IN-KA', 'Mangaluru'), ('IN-KA', 'Mysuru'), ('IN-KA', 'Raichur'), ('IN-KA', 'Ramanagara'), ('IN-KA', 'Shivamogga'), ('IN-KA', 'Tumakuru'), ('IN-KA', 'Udupi'), ('IN-KA', 'Vijayapura'),
		('IN-KL', 'Alappuzha'), ('IN-KL', 'Kannur'), ('IN-KL', 'Kasaragod'), ('IN-KL', 'Kochi'), ('IN-KL', 'Kollam'), ('IN-KL', 'Kottayam'), ('IN-KL', 'Kozhikode'), ('IN-KL', 'Malappuram'), ('IN-KL', 'Palakkad'), ('IN-KL', 'Pathanamthitta'), ('IN-KL', 'Thiruvananthapuram'), ('IN-KL', 'Thrissur'), ('IN-KL', 'Wayanad'),
		('IN-MP', 'Bhopal'), ('IN-MP', 'Burhanpur'), ('IN-MP', 'Chhindwara'), ('IN-MP', 'Dewas'), ('IN-MP', 'Guna'), ('IN-MP', 'Gwalior'), ('IN-MP', 'Indore'), ('IN-MP', 'Itarsi'), ('IN-MP', 'Jabalpur'), ('IN-MP', 'Katni'), ('IN-MP', 'Khandwa'), ('IN-MP', 'Mandsaur'), ('IN-MP', 'Morena'), ('IN-MP', 'Narmadapuram'), ('IN-MP', 'Neemuch'), ('IN-MP', 'Ratlam'), ('IN-MP', 'Rewa'), ('IN-MP', 'Sagar'), ('IN-MP', 'Satna'), ('IN-MP', 'Sehore'), ('IN-MP', 'Shivpuri'), ('IN-MP', 'Singrauli'), ('IN-MP', 'Ujjain'), ('IN-MP', 'Vidisha'),
		('IN-MH', 'Ahmednagar'), ('IN-MH', 'Akola'), ('IN-MH', 'Amravati'), ('IN-MH', 'Andheri'), ('IN-MH', 'Aurangabad'), ('IN-MH', 'Bandra'), ('IN-MH', 'Baramati'), ('IN-MH', 'Beed'), ('IN-MH', 'Bhiwandi'), ('IN-MH', 'Bhusawal'), ('IN-MH', 'Chandrapur'), ('IN-MH', 'Dhule'), ('IN-MH', 'Dombivli'), ('IN-MH', 'Gondia'), ('IN-MH', 'Ichalkaranji'), ('IN-MH', 'Jalgaon'), ('IN-MH', 'Jalna'), ('IN-MH', 'Kalyan'), ('IN-MH', 'Kolhapur'), ('IN-MH', 'Latur'), ('IN-MH', 'Malegaon'), ('IN-MH', 'Mira-Bhayandar'), ('IN-MH', 'Mumbai'), ('IN-MH', 'Nagpur'), ('IN-MH', 'Nanded'), ('IN-MH', 'Nashik'), ('IN-MH', 'Navi Mumbai'), ('IN-MH', 'Osmanabad'), ('IN-MH', 'Palghar'), ('IN-MH', 'Panvel'), ('IN-MH', 'Parbhani'), ('IN-MH', 'Pimpri-Chinchwad'), ('IN-MH', 'Pune'), ('IN-MH', 'Ratnagiri'), ('IN-MH', 'Sangli'), ('IN-MH', 'Satara'), ('IN-MH', 'Solapur'), ('IN-MH', 'Thane'), ('IN-MH', 'Ulhasnagar'), ('IN-MH', 'Vasai-Virar'), ('IN-MH', 'Wardha'), ('IN-MH', 'Yavatmal'),
		('IN-MN', 'Bishnupur'), ('IN-MN', 'Chandel'), ('IN-MN', 'Churachandpur'), ('IN-MN', 'Imphal'), ('IN-MN', 'Kakching'), ('IN-MN', 'Senapati'), ('IN-MN', 'Tamenglong'), ('IN-MN', 'Thoubal'), ('IN-MN', 'Ukhrul'),
		('IN-ML', 'Baghmara'), ('IN-ML', 'Jowai'), ('IN-ML', 'Nongpoh'), ('IN-ML', 'Nongstoin'), ('IN-ML', 'Shillong'), ('IN-ML', 'Tura'), ('IN-ML', 'Williamnagar'),
		('IN-MZ', 'Aizawl'), ('IN-MZ', 'Champhai'), ('IN-MZ', 'Kolasib'), ('IN-MZ', 'Lawngtlai'), ('IN-MZ', 'Lunglei'), ('IN-MZ', 'Mamit'), ('IN-MZ', 'Saiha'), ('IN-MZ', 'Serchhip'),
		('IN-NL', 'Dimapur'), ('IN-NL', 'Kiphire'), ('IN-NL', 'Kohima'), ('IN-NL', 'Longleng'), ('IN-NL', 'Mokokchung'), ('IN-NL', 'Mon'), ('IN-NL', 'Peren'), ('IN-NL', 'Phek'), ('IN-NL', 'Tuensang'), ('IN-NL', 'Wokha'), ('IN-NL', 'Zunheboto'),
		('IN-OR', 'Balangir'), ('IN-OR', 'Balasore'), ('IN-OR', 'Baripada'), ('IN-OR', 'Berhampur'), ('IN-OR', 'Bhadrak'), ('IN-OR', 'Bhubaneswar'), ('IN-OR', 'Cuttack'), ('IN-OR', 'Dhenkanal'), ('IN-OR', 'Jajpur'), ('IN-OR', 'Jharsuguda'), ('IN-OR', 'Kendrapara'), ('IN-OR', 'Keonjhar'), ('IN-OR', 'Koraput'), ('IN-OR', 'Puri'), ('IN-OR', 'Rayagada'), ('IN-OR', 'Rourkela'), ('IN-OR', 'Sambalpur'),
		('IN-PB', 'Abohar'), ('IN-PB', 'Amritsar'), ('IN-PB', 'Barnala'), ('IN-PB', 'Bathinda'), ('IN-PB', 'Faridkot'), ('IN-PB', 'Fazilka'), ('IN-PB', 'Firozpur'), ('IN-PB', 'Hoshiarpur'), ('IN-PB', 'Jalandhar'), ('IN-PB', 'Kapurthala'), ('IN-PB', 'Khanna'), ('IN-PB', 'Ludhiana'), ('IN-PB', 'Mansa'), ('IN-PB', 'Moga'), ('IN-PB', 'Mohali'), ('IN-PB', 'Muktsar'), ('IN-PB', 'Pathankot'), ('IN-PB', 'Patiala'), ('IN-PB', 'Phagwara'), ('IN-PB', 'Rupnagar'), ('IN-PB', 'Sangrur'), ('IN-PB', 'Tarn Taran'),
		('IN-RJ', 'Ajmer'), ('IN-RJ', 'Alwar'), ('IN-RJ', 'Banswara'), ('IN-RJ', 'Baran'), ('IN-RJ', 'Barmer'), ('IN-RJ', 'Bharatpur'), ('IN-RJ', 'Bhilwara'), ('IN-RJ', 'Bikaner'), ('IN-RJ', 'Bundi'), ('IN-RJ', 'Chittorgarh'), ('IN-RJ', 'Churu'), ('IN-RJ', 'Dausa'), ('IN-RJ', 'Dholpur'), ('IN-RJ', 'Hanumangarh'), ('IN-RJ', 'Jaipur'), ('IN-RJ', 'Jaisalmer'), ('IN-RJ', 'Jhalawar'), ('IN-RJ', 'Jhunjhunu'), ('IN-RJ', 'Jodhpur'), ('IN-RJ', 'Karauli'), ('IN-RJ', 'Kota'), ('IN-RJ', 'Nagaur'), ('IN-RJ', 'Pali'), ('IN-RJ', 'Sikar'), ('IN-RJ', 'Sirohi'), ('IN-RJ', 'Sri Ganganagar'), ('IN-RJ', 'Tonk'), ('IN-RJ', 'Udaipur'),
		('IN-SK', 'Gangtok'), ('IN-SK', 'Gyalshing'), ('IN-SK', 'Mangan'), ('IN-SK', 'Namchi'), ('IN-SK', 'Pakyong'), ('IN-SK', 'Ravangla'), ('IN-SK', 'Soreng'),
		('IN-TN', 'Ambattur'), ('IN-TN', 'Avadi'), ('IN-TN', 'Chennai'), ('IN-TN', 'Coimbatore'), ('IN-TN', 'Cuddalore'), ('IN-TN', 'Dindigul'), ('IN-TN', 'Erode'), ('IN-TN', 'Hosur'), ('IN-TN', 'Kanchipuram'), ('IN-TN', 'Karur'), ('IN-TN', 'Kumbakonam'), ('IN-TN', 'Madurai'), ('IN-TN', 'Nagercoil'), ('IN-TN', 'Ooty'), ('IN-TN', 'Pollachi'), ('IN-TN', 'Rajapalayam'), ('IN-TN', 'Salem'), ('IN-TN', 'Thanjavur'), ('IN-TN', 'Thoothukudi'), ('IN-TN', 'Tiruchirappalli'), ('IN-TN', 'Tirunelveli'), ('IN-TN', 'Tiruppur'), ('IN-TN', 'Vellore'), ('IN-TN', 'Villupuram'),
		('IN-TG', 'Adilabad'), ('IN-TG', 'Hyderabad'), ('IN-TG', 'Jagtial'), ('IN-TG', 'Karimnagar'), ('IN-TG', 'Khammam'), ('IN-TG', 'Mahbubnagar'), ('IN-TG', 'Mancherial'), ('IN-TG', 'Medak'), ('IN-TG', 'Nalgonda'), ('IN-TG', 'Nizamabad'), ('IN-TG', 'Ramagundam'), ('IN-TG', 'Sangareddy'), ('IN-TG', 'Secunderabad'), ('IN-TG', 'Siddipet'), ('IN-TG', 'Suryapet'), ('IN-TG', 'Warangal'),
		('IN-TR', 'Agartala'), ('IN-TR', 'Ambassa'), ('IN-TR', 'Belonia'), ('IN-TR', 'Dharmanagar'), ('IN-TR', 'Kailashahar'), ('IN-TR', 'Khowai'), ('IN-TR', 'Udaipur'),
		('IN-UP', 'Agra'), ('IN-UP', 'Aligarh'), ('IN-UP', 'Ayodhya'), ('IN-UP', 'Azamgarh'), ('IN-UP', 'Bahraich'), ('IN-UP', 'Ballia'), ('IN-UP', 'Banda'), ('IN-UP', 'Barabanki'), ('IN-UP', 'Bareilly'), ('IN-UP', 'Basti'), ('IN-UP', 'Bijnor'), ('IN-UP', 'Bulandshahr'), ('IN-UP', 'Etawah'), ('IN-UP', 'Farrukhabad'), ('IN-UP', 'Firozabad'), ('IN-UP', 'Ghaziabad'), ('IN-UP', 'Ghazipur'), ('IN-UP', 'Gonda'), ('IN-UP', 'Gorakhpur'), ('IN-UP', 'Greater Noida'), ('IN-UP', 'Hapur'), ('IN-UP', 'Hardoi'), ('IN-UP', 'Jaunpur'), ('IN-UP', 'Jhansi'), ('IN-UP', 'Kanpur'), ('IN-UP', 'Lakhimpur'), ('IN-UP', 'Lucknow'), ('IN-UP', 'Mathura'), ('IN-UP', 'Meerut'), ('IN-UP', 'Mirzapur'), ('IN-UP', 'Moradabad'), ('IN-UP', 'Muzaffarnagar'), ('IN-UP', 'Noida'), ('IN-UP', 'Prayagraj'), ('IN-UP', 'Raebareli'), ('IN-UP', 'Rampur'), ('IN-UP', 'Saharanpur'), ('IN-UP', 'Shahjahanpur'), ('IN-UP', 'Sitapur'), ('IN-UP', 'Sultanpur'), ('IN-UP', 'Unnao'), ('IN-UP', 'Varanasi'),
		('IN-UT', 'Almora'), ('IN-UT', 'Bageshwar'), ('IN-UT', 'Chamoli'), ('IN-UT', 'Dehradun'), ('IN-UT', 'Haldwani'), ('IN-UT', 'Haridwar'), ('IN-UT', 'Kashipur'), ('IN-UT', 'Kotdwar'), ('IN-UT', 'Nainital'), ('IN-UT', 'Pithoragarh'), ('IN-UT', 'Rishikesh'), ('IN-UT', 'Roorkee'), ('IN-UT', 'Rudrapur'), ('IN-UT', 'Tehri'), ('IN-UT', 'Uttarkashi'),
		('IN-WB', 'Alipurduar'), ('IN-WB', 'Asansol'), ('IN-WB', 'Baharampur'), ('IN-WB', 'Balurghat'), ('IN-WB', 'Bankura'), ('IN-WB', 'Barasat'), ('IN-WB', 'Bardhaman'), ('IN-WB', 'Barrackpore'), ('IN-WB', 'Basirhat'), ('IN-WB', 'Cooch Behar'), ('IN-WB', 'Darjeeling'), ('IN-WB', 'Durgapur'), ('IN-WB', 'Haldia'), ('IN-WB', 'Howrah'), ('IN-WB', 'Jalpaiguri'), ('IN-WB', 'Kalyani'), ('IN-WB', 'Kharagpur'), ('IN-WB', 'Kolkata'), ('IN-WB', 'Krishnanagar'), ('IN-WB', 'Malda'), ('IN-WB', 'Midnapore'), ('IN-WB', 'Purulia'), ('IN-WB', 'Raiganj'), ('IN-WB', 'Siliguri'),
		('IN-AN', 'Bamboo Flat'), ('IN-AN', 'Car Nicobar'), ('IN-AN', 'Diglipur'), ('IN-AN', 'Mayabunder'), ('IN-AN', 'Port Blair'), ('IN-AN', 'Rangat'),
		('IN-CH', 'Chandigarh'), ('IN-CH', 'Manimajra'),
		('IN-DN', 'Dadra'), ('IN-DN', 'Daman'), ('IN-DN', 'Diu'), ('IN-DN', 'Silvassa'),
		('IN-DL', 'Central Delhi'), ('IN-DL', 'Delhi'), ('IN-DL', 'Dwarka'), ('IN-DL', 'East Delhi'), ('IN-DL', 'Karol Bagh'), ('IN-DL', 'New Delhi'), ('IN-DL', 'North Delhi'), ('IN-DL', 'Rohini'), ('IN-DL', 'South Delhi'), ('IN-DL', 'West Delhi'),
		('IN-JK', 'Anantnag'), ('IN-JK', 'Baramulla'), ('IN-JK', 'Budgam'), ('IN-JK', 'Doda'), ('IN-JK', 'Ganderbal'), ('IN-JK', 'Jammu'), ('IN-JK', 'Kathua'), ('IN-JK', 'Kishtwar'), ('IN-JK', 'Kupwara'), ('IN-JK', 'Poonch'), ('IN-JK', 'Pulwama'), ('IN-JK', 'Rajouri'), ('IN-JK', 'Samba'), ('IN-JK', 'Sopore'), ('IN-JK', 'Srinagar'), ('IN-JK', 'Udhampur'),
		('IN-LA', 'Diskit'), ('IN-LA', 'Kargil'), ('IN-LA', 'Leh'), ('IN-LA', 'Nubra'), ('IN-LA', 'Zanskar'),
		('IN-LD', 'Agatti'), ('IN-LD', 'Amini'), ('IN-LD', 'Andrott'), ('IN-LD', 'Kavaratti'), ('IN-LD', 'Minicoy'),
		('IN-PY', 'Karaikal'), ('IN-PY', 'Mahe'), ('IN-PY', 'Puducherry'), ('IN-PY', 'Yanam')
)
INSERT INTO matching.master_cities (state_code, name, is_active)
SELECT DISTINCT state_code, name, TRUE
FROM cities
WHERE NULLIF(TRIM(name), '') IS NOT NULL
ON CONFLICT (state_code, name) DO UPDATE SET
	is_active = TRUE;

INSERT INTO matching.master_religions (name, sort_order, is_active) VALUES
	('Hindu', 10, TRUE),
	('Muslim', 20, TRUE),
	('Christian', 30, TRUE),
	('Sikh', 40, TRUE),
	('Buddhist', 50, TRUE),
	('Jain', 60, TRUE),
	('Parsi', 70, TRUE),
	('Jewish', 80, TRUE),
	('Bahai', 90, TRUE),
	('Tribal / Indigenous', 100, TRUE),
	('Spiritual', 110, TRUE),
	('Other', 120, TRUE),
	('Prefer not to say', 130, TRUE)
ON CONFLICT (name) DO UPDATE SET
	sort_order = EXCLUDED.sort_order,
	is_active = TRUE;

INSERT INTO matching.master_mother_tongues (name, sort_order, is_active) VALUES
	('Assamese', 10, TRUE),
	('Bengali', 20, TRUE),
	('Bodo', 30, TRUE),
	('Dogri', 40, TRUE),
	('English', 50, TRUE),
	('Gujarati', 60, TRUE),
	('Hindi', 70, TRUE),
	('Kannada', 80, TRUE),
	('Kashmiri', 90, TRUE),
	('Konkani', 100, TRUE),
	('Maithili', 110, TRUE),
	('Malayalam', 120, TRUE),
	('Manipuri', 130, TRUE),
	('Marathi', 140, TRUE),
	('Nepali', 150, TRUE),
	('Odia', 160, TRUE),
	('Punjabi', 170, TRUE),
	('Sanskrit', 180, TRUE),
	('Santali', 190, TRUE),
	('Sindhi', 200, TRUE),
	('Tamil', 210, TRUE),
	('Telugu', 220, TRUE),
	('Urdu', 230, TRUE)
ON CONFLICT (name) DO UPDATE SET
	sort_order = EXCLUDED.sort_order,
	is_active = TRUE;

INSERT INTO matching.master_languages (code, name, sort_order, is_active) VALUES
	('en', 'English', 10, TRUE),
	('hi', 'Hindi', 20, TRUE),
	('ta', 'Tamil', 30, TRUE),
	('te', 'Telugu', 40, TRUE),
	('kn', 'Kannada', 50, TRUE),
	('ml', 'Malayalam', 60, TRUE),
	('mr', 'Marathi', 70, TRUE),
	('gu', 'Gujarati', 80, TRUE),
	('pa', 'Punjabi', 90, TRUE),
	('bn', 'Bengali', 100, TRUE),
	('or', 'Odia', 110, TRUE),
	('ur', 'Urdu', 120, TRUE),
	('as', 'Assamese', 130, TRUE),
	('kok', 'Konkani', 140, TRUE),
	('ks', 'Kashmiri', 150, TRUE),
	('ne', 'Nepali', 160, TRUE),
	('sa', 'Sanskrit', 170, TRUE)
ON CONFLICT (name) DO UPDATE SET
	code = EXCLUDED.code,
	sort_order = EXCLUDED.sort_order,
	is_active = TRUE;

INSERT INTO matching.master_workout_frequencies (name, sort_order, is_active) VALUES
	('Never', 10, TRUE),
	('1-2 times a week', 20, TRUE),
	('3-4 times a week', 30, TRUE),
	('5+ times a week', 40, TRUE),
	('Daily', 50, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

INSERT INTO matching.master_diet_preferences (name, sort_order, is_active) VALUES
	('No preference', 10, TRUE),
	('Vegetarian', 20, TRUE),
	('Eggetarian', 30, TRUE),
	('Non-vegetarian', 40, TRUE),
	('Vegan', 50, TRUE),
	('Jain', 60, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

INSERT INTO matching.master_diet_types (name, sort_order, is_active) VALUES
	('Balanced', 10, TRUE),
	('High Protein', 20, TRUE),
	('Low Carb', 30, TRUE),
	('Keto', 40, TRUE),
	('Mediterranean', 50, TRUE),
	('Intermittent Fasting', 60, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

INSERT INTO matching.master_sleep_schedules (name, sort_order, is_active) VALUES
	('Early bird', 10, TRUE),
	('Night owl', 20, TRUE),
	('Flexible', 30, TRUE),
	('Shift based', 40, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

INSERT INTO matching.master_travel_styles (name, sort_order, is_active) VALUES
	('Homebody', 10, TRUE),
	('Occasional traveler', 20, TRUE),
	('Frequent traveler', 30, TRUE),
	('Adventure seeker', 40, TRUE),
	('Luxury traveler', 50, TRUE),
	('Backpacker', 60, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

INSERT INTO matching.master_political_comfort_ranges (name, sort_order, is_active) VALUES
	('Similar views only', 10, TRUE),
	('Open to differences', 20, TRUE),
	('Prefer not to discuss', 30, TRUE),
	('No strong preference', 40, TRUE)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order, is_active = TRUE;

CREATE OR REPLACE VIEW public.master_countries AS
SELECT id, code, name, is_active, created_at
FROM matching.master_countries;

CREATE OR REPLACE VIEW public.master_states AS
SELECT id, country_code, code, name, is_union_territory, is_active, created_at
FROM matching.master_states;

CREATE OR REPLACE VIEW public.master_cities AS
SELECT id, state_code, name, is_active, created_at
FROM matching.master_cities;

CREATE OR REPLACE VIEW public.master_religions AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_religions;

CREATE OR REPLACE VIEW public.master_mother_tongues AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_mother_tongues;

CREATE OR REPLACE VIEW public.master_languages AS
SELECT id, code, name, sort_order, is_active, created_at
FROM matching.master_languages;

CREATE OR REPLACE VIEW public.master_diet_preferences AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_diet_preferences;

CREATE OR REPLACE VIEW public.master_workout_frequencies AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_workout_frequencies;

CREATE OR REPLACE VIEW public.master_diet_types AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_diet_types;

CREATE OR REPLACE VIEW public.master_sleep_schedules AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_sleep_schedules;

CREATE OR REPLACE VIEW public.master_travel_styles AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_travel_styles;

CREATE OR REPLACE VIEW public.master_political_comfort_ranges AS
SELECT id, name, sort_order, is_active, created_at
FROM matching.master_political_comfort_ranges;

COMMIT;
