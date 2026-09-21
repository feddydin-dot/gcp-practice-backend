# Dedicated runtime identity for the backend Cloud Run service
resource "google_service_account" "backend_sa" {
  project      = var.project_id
  account_id   = "practice-backend-sa"
  display_name = "Practice Backend Cloud Run service account"
}

resource "google_project_iam_member" "backend_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}
