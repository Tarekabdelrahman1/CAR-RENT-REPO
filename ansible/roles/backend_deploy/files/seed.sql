-- ============================================================
--  CarRento  |  Seed Data
-- ============================================================

-- Locations
INSERT INTO locations (id, name, city, address, latitude, longitude) VALUES
  ('11111111-0000-0000-0000-000000000001', 'Cairo Airport Branch',    'Cairo',       'Cairo International Airport, Terminal 2', 30.1219, 31.4056),
  ('11111111-0000-0000-0000-000000000002', 'Giza Downtown Branch',    'Giza',        '26 July St, Mohandessin, Giza',            30.0626, 31.2497),
  ('11111111-0000-0000-0000-000000000003', 'Alexandria Corniche',     'Alexandria',  'Corniche El Nil, Sidi Gaber',              31.2001, 29.9187);

-- Demo admin user  (password: "secret"  →  bcrypt hash)
INSERT INTO users (id, name, email, password, role) VALUES
  ('22222222-0000-0000-0000-000000000001', 'Admin User', 'admin@carrento.eg',
   '$2y$12$placeholder_bcrypt_hash_replace_me', 'admin');

-- Cars
INSERT INTO cars (id, location_id, brand, model, year, category, transmission, fuel_type, seats, price_per_day, image_url, description, features) VALUES
  ('33333333-0000-0000-0000-000000000001',
   '11111111-0000-0000-0000-000000000001',
   'Toyota','Corolla',2023,'economy','automatic','petrol',5,35.00,
   'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800',
   'Reliable everyday sedan, perfect for city driving.',
   '["AC","Bluetooth","USB Charger","Rear Camera"]'),

  ('33333333-0000-0000-0000-000000000002',
   '11111111-0000-0000-0000-000000000001',
   'BMW','5 Series',2023,'luxury','automatic','petrol',5,120.00,
   'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800',
   'Executive luxury with sport-tuned suspension.',
   '["Leather Seats","Sunroof","Navigation","Heated Seats","Premium Sound"]'),

  ('33333333-0000-0000-0000-000000000003',
   '11111111-0000-0000-0000-000000000002',
   'Toyota','Land Cruiser',2022,'suv','automatic','petrol',7,150.00,
   'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
   'Legendary off-road capability with 7-seat comfort.',
   '["7 Seats","4WD","Navigation","Premium Sound","Roof Rails"]'),

  ('33333333-0000-0000-0000-000000000004',
   '11111111-0000-0000-0000-000000000002',
   'Hyundai','Tucson',2023,'suv','automatic','hybrid',5,75.00,
   'https://images.unsplash.com/photo-1617531653332-bd46c16f4d68?w=800',
   'Fuel-efficient hybrid SUV with modern tech.',
   '["Hybrid","Lane Assist","360 Camera","Wireless Charging"]'),

  ('33333333-0000-0000-0000-000000000005',
   '11111111-0000-0000-0000-000000000003',
   'Porsche','911 Carrera',2022,'sports','automatic','petrol',2,280.00,
   'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
   'Iconic sports car. 450hp. Pure driving pleasure.',
   '["Sport Mode","Bose Sound","Carbon Trim","Launch Control"]'),

  ('33333333-0000-0000-0000-000000000006',
   '11111111-0000-0000-0000-000000000003',
   'Kia','Picanto',2023,'economy','manual','petrol',5,22.00,
   'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
   'Compact and economical, great for tight city streets.',
   '["AC","USB Charger","Bluetooth"]');
