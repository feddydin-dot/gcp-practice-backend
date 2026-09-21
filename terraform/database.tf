# Enable required APIs
resource "google_project_service" "sqladmin_api" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "secretmanager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

# Cloud SQL for PostgreSQL instance
resource "google_sql_database_instance" "instance" {
  name             = "practice-backend-db"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  # Practice project: allow easy `terraform destroy` cleanup.
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_autoresize   = false

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled = false
    }
  }

  depends_on = [google_project_service.sqladmin_api]
}

resource "google_sql_database" "database" {
  name     = "notes"
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
}

resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "google_sql_user" "user" {
  name     = "notes_app"
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result
}

# Store the DB password in Secret Manager rather than a plain Cloud Run env var
resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "practice-backend-db-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret_iam_member" "backend_secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backend_sa.email}"
}
