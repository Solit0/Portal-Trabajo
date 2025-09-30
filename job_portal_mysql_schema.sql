
-- ============================================================
--  Job Portal - Esquema Normalizado (MySQL 8.0+)
--  Charset/Collation recomendados para español
-- ============================================================

CREATE DATABASE IF NOT EXISTS job_portal
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE job_portal;

-- Asegurar InnoDB
SET default_storage_engine=INNODB;

-- ============================================================
--  Tablas de catálogo (lookups)
-- ============================================================

CREATE TABLE roles (
  id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE  -- candidate | employer | admin
) ENGINE=InnoDB;

CREATE TABLE company_sizes (
  id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE,      -- Micro, Small, Medium...
  min_employees INT UNSIGNED NULL,
  max_employees INT UNSIGNED NULL
) ENGINE=InnoDB;

CREATE TABLE job_types (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE       -- full-time, part-time, contract, internship, remote
) ENGINE=InnoDB;

CREATE TABLE experience_levels (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE       -- Intern, Junior, Mid, Senior, Lead
) ENGINE=InnoDB;

CREATE TABLE job_statuses (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE       -- open, closed
) ENGINE=InnoDB;

CREATE TABLE application_statuses (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE       -- applied, review, accepted, rejected
) ENGINE=InnoDB;

CREATE TABLE resource_types (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL UNIQUE       -- article, tutorial, video
) ENGINE=InnoDB;

CREATE TABLE sectors (
  id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(64) NOT NULL UNIQUE       -- Tecnología, Marketing, Finanzas, etc.
) ENGINE=InnoDB;

CREATE TABLE skills (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(64) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ============================================================
--  Usuarios y Empresas
-- ============================================================

CREATE TABLE users (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  role_id TINYINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(40) NULL,
  city VARCHAR(100) NULL,
  country VARCHAR(100) NULL,
  headline VARCHAR(160) NULL,
  bio TEXT NULL,
  avatar_url VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE companies (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  owner_user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  slug VARCHAR(180) NOT NULL UNIQUE,
  description TEXT NULL,
  website VARCHAR(180) NULL,
  city VARCHAR(100) NULL,
  country VARCHAR(100) NULL,
  size_id TINYINT UNSIGNED NULL,
  founded_year SMALLINT UNSIGNED NULL,
  logo_url VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_companies_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_companies_size FOREIGN KEY (size_id) REFERENCES company_sizes(id)
) ENGINE=InnoDB;

-- Miembros de empresa (permite que varios usuarios gestionen una empresa)
CREATE TABLE company_members (
  user_id BIGINT UNSIGNED NOT NULL,
  company_id BIGINT UNSIGNED NOT NULL,
  company_role VARCHAR(32) NOT NULL DEFAULT 'member', -- owner/manager/recruiter/member
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, company_id),
  CONSTRAINT fk_company_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_company_members_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  Empleos
-- ============================================================

CREATE TABLE jobs (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  company_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  description MEDIUMTEXT NOT NULL,
  city VARCHAR(100) NULL,
  country VARCHAR(100) NULL,
  type_id SMALLINT UNSIGNED NOT NULL,
  experience_level_id SMALLINT UNSIGNED NOT NULL,
  sector_id SMALLINT UNSIGNED NULL,
  salary_min DECIMAL(12,2) NULL,
  salary_max DECIMAL(12,2) NULL,
  status_id SMALLINT UNSIGNED NOT NULL,
  posted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_jobs_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
  CONSTRAINT fk_jobs_type FOREIGN KEY (type_id) REFERENCES job_types(id),
  CONSTRAINT fk_jobs_exp FOREIGN KEY (experience_level_id) REFERENCES experience_levels(id),
  CONSTRAINT fk_jobs_sector FOREIGN KEY (sector_id) REFERENCES sectors(id),
  CONSTRAINT fk_jobs_status FOREIGN KEY (status_id) REFERENCES job_statuses(id),
  FULLTEXT KEY ft_jobs_title_desc (title, description)
) ENGINE=InnoDB;

-- Habilidades requeridas por empleo
CREATE TABLE job_skills (
  job_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  importance TINYINT UNSIGNED NULL,  -- 1..5
  PRIMARY KEY (job_id, skill_id),
  CONSTRAINT fk_job_skills_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  CONSTRAINT fk_job_skills_skill FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  Postulaciones (Applications)
-- ============================================================

CREATE TABLE applications (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  job_id BIGINT UNSIGNED NOT NULL,
  candidate_id BIGINT UNSIGNED NOT NULL,
  cover_letter MEDIUMTEXT NULL,
  cv_url VARCHAR(255) NULL,
  status_id SMALLINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_apps_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  CONSTRAINT fk_apps_user FOREIGN KEY (candidate_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_apps_status FOREIGN KEY (status_id) REFERENCES application_statuses(id),
  UNIQUE KEY uq_app_unique (job_id, candidate_id)
) ENGINE=InnoDB;

-- Guardados (favoritos) de empleos por candidatos
CREATE TABLE saved_jobs (
  user_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, job_id),
  CONSTRAINT fk_saved_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_saved_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  Valoraciones de empresas
-- ============================================================

CREATE TABLE reviews (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  company_id BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
  UNIQUE KEY uq_review_once (company_id, author_id)
) ENGINE=InnoDB;

-- ============================================================
--  Recursos (artículos, tutoriales, videos)
-- ============================================================

CREATE TABLE resources (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT UNSIGNED NULL,        -- puede ser nulo si es un link externo sin autor local
  type_id SMALLINT UNSIGNED NOT NULL,
  title VARCHAR(200) NOT NULL,
  excerpt VARCHAR(500) NULL,
  content MEDIUMTEXT NULL,               -- opcional si alojas contenido interno
  url VARCHAR(255) NULL,                 -- opcional si enlazas a un recurso externo
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_resources_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_resources_type FOREIGN KEY (type_id) REFERENCES resource_types(id)
) ENGINE=InnoDB;

CREATE TABLE resource_tags (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(64) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE resource_tag_map (
  resource_id BIGINT UNSIGNED NOT NULL,
  tag_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (resource_id, tag_id),
  CONSTRAINT fk_rtag_res FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE,
  CONSTRAINT fk_rtag_tag FOREIGN KEY (tag_id) REFERENCES resource_tags(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  Foros
-- ============================================================

CREATE TABLE forum_categories (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL UNIQUE,
  slug VARCHAR(140) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE forum_threads (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  category_id BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(200) NOT NULL,
  body MEDIUMTEXT NOT NULL,
  is_pinned TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_threads_cat FOREIGN KEY (category_id) REFERENCES forum_categories(id) ON DELETE CASCADE,
  CONSTRAINT fk_threads_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_threads_cat_created (category_id, created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE forum_posts (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  thread_id BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  body MEDIUMTEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_posts_thread FOREIGN KEY (thread_id) REFERENCES forum_threads(id) ON DELETE CASCADE,
  CONSTRAINT fk_posts_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_posts_thread_created (thread_id, created_at ASC)
) ENGINE=InnoDB;

-- ============================================================
--  Habilidades del usuario (para matching futuro y perfil)
-- ============================================================

CREATE TABLE user_skills (
  user_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  level TINYINT UNSIGNED NULL,  -- 1..5
  PRIMARY KEY (user_id, skill_id),
  CONSTRAINT fk_userskills_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_userskills_skill FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  Índices de soporte para filtros comunes
-- ============================================================

CREATE INDEX idx_jobs_company ON jobs(company_id);
CREATE INDEX idx_jobs_filters ON jobs(type_id, experience_level_id, sector_id, city, posted_at);
CREATE INDEX idx_jobs_status ON jobs(status_id, posted_at);
CREATE INDEX idx_apps_user ON applications(candidate_id, created_at);
CREATE INDEX idx_apps_job ON applications(job_id, created_at);
CREATE INDEX idx_reviews_company ON reviews(company_id, created_at);
CREATE INDEX idx_companies_slug ON companies(slug);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================
--  Datos iniciales (catálogos)
-- ============================================================

INSERT INTO roles (name) VALUES ('candidate'), ('employer'), ('admin');

INSERT INTO company_sizes (name, min_employees, max_employees) VALUES
  ('Micro', 1, 10),
  ('Small', 11, 50),
  ('Medium', 51, 200),
  ('Large', 201, 500),
  ('Enterprise', 501, NULL);

INSERT INTO job_types (name) VALUES
  ('full-time'), ('part-time'), ('contract'), ('internship'), ('remote');

INSERT INTO experience_levels (name) VALUES
  ('Intern'), ('Junior'), ('Mid'), ('Senior'), ('Lead');

INSERT INTO job_statuses (name) VALUES ('open'), ('closed');

INSERT INTO application_statuses (name) VALUES ('applied'), ('review'), ('accepted'), ('rejected');

INSERT INTO resource_types (name) VALUES ('article'), ('tutorial'), ('video');

INSERT INTO sectors (name) VALUES ('Tecnología'), ('Marketing'), ('Finanzas'), ('Ventas'), ('Operaciones'), ('Diseño'), ('Recursos Humanos');

-- (Opcional) Habilidades comunes
INSERT INTO skills (name) VALUES ('JavaScript'), ('Node.js'), ('Express'), ('SQL'), ('MySQL'), ('React'), ('UX'), ('QA'), ('Docker');
