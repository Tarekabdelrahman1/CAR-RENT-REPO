-- ============================================================
--  CarRento  |  PostgreSQL Schema
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- 1. USERS
-- ------------------------------------------------------------
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100)        NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    password      VARCHAR(255)        NOT NULL,
    phone         VARCHAR(20),
    avatar_url    TEXT,
    role          VARCHAR(20)  DEFAULT 'customer' CHECK (role IN ('customer','admin')),
    email_verified_at TIMESTAMP,
    created_at    TIMESTAMP    DEFAULT NOW(),
    updated_at    TIMESTAMP    DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2. LOCATIONS
-- ------------------------------------------------------------
CREATE TABLE locations (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL,
    city       VARCHAR(80)  NOT NULL,
    address    TEXT,
    latitude   DECIMAL(10,7),
    longitude  DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 3. CARS
-- ------------------------------------------------------------
CREATE TABLE cars (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id     UUID REFERENCES locations(id) ON DELETE SET NULL,
    brand           VARCHAR(60)  NOT NULL,
    model           VARCHAR(60)  NOT NULL,
    year            SMALLINT     NOT NULL,
    category        VARCHAR(30)  CHECK (category IN ('economy','comfort','luxury','suv','sports')),
    transmission    VARCHAR(20)  DEFAULT 'automatic' CHECK (transmission IN ('manual','automatic')),
    fuel_type       VARCHAR(20)  DEFAULT 'petrol' CHECK (fuel_type IN ('petrol','diesel','electric','hybrid')),
    seats           SMALLINT     DEFAULT 5,
    price_per_day   DECIMAL(10,2) NOT NULL,
    image_url       TEXT,
    description     TEXT,
    mileage         INTEGER      DEFAULT 0,
    is_available    BOOLEAN      DEFAULT TRUE,
    features        JSONB        DEFAULT '[]',
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 4. RENTALS
-- ------------------------------------------------------------
CREATE TABLE rentals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
    car_id          UUID NOT NULL REFERENCES cars(id)      ON DELETE CASCADE,
    pickup_location UUID REFERENCES locations(id),
    dropoff_location UUID REFERENCES locations(id),
    start_date      DATE          NOT NULL,
    end_date        DATE          NOT NULL,
    total_days      INTEGER       GENERATED ALWAYS AS (end_date - start_date) STORED,
    price_per_day   DECIMAL(10,2) NOT NULL,
    total_price     DECIMAL(10,2) NOT NULL,
    status          VARCHAR(20)   DEFAULT 'pending'
                       CHECK (status IN ('pending','confirmed','active','completed','cancelled')),
    payment_status  VARCHAR(20)   DEFAULT 'unpaid'
                       CHECK (payment_status IN ('unpaid','paid','refunded')),
    notes           TEXT,
    created_at      TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     DEFAULT NOW(),

    CONSTRAINT no_overlap EXCLUDE USING gist (
        car_id WITH =,
        daterange(start_date, end_date, '[)') WITH &&
    ) WHERE (status NOT IN ('cancelled'))
);

-- ------------------------------------------------------------
-- 5. REVIEWS
-- ------------------------------------------------------------
CREATE TABLE reviews (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rental_id  UUID UNIQUE NOT NULL REFERENCES rentals(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id)          ON DELETE CASCADE,
    car_id     UUID NOT NULL REFERENCES cars(id)           ON DELETE CASCADE,
    rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 6. INDEXES
-- ------------------------------------------------------------
CREATE INDEX idx_cars_location     ON cars(location_id);
CREATE INDEX idx_cars_available    ON cars(is_available);
CREATE INDEX idx_cars_category     ON cars(category);
CREATE INDEX idx_rentals_user      ON rentals(user_id);
CREATE INDEX idx_rentals_car       ON rentals(car_id);
CREATE INDEX idx_rentals_status    ON rentals(status);
CREATE INDEX idx_rentals_dates     ON rentals(start_date, end_date);

-- ------------------------------------------------------------
-- 7. updated_at TRIGGER
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at  BEFORE UPDATE ON users  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER cars_updated_at   BEFORE UPDATE ON cars   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER rentals_updated_at BEFORE UPDATE ON rentals FOR EACH ROW EXECUTE FUNCTION set_updated_at();
