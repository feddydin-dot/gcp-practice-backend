# GCS bucket for uploaded note photos
resource "google_storage_bucket" "photos" {
  name                        = "${var.project_id}-notes-photos"
  project                     = var.project_id
  location                    = "US"
  uniform_bucket_level_access = true

  # Practice project: allow `terraform destroy` to remove non-empty bucket.
  force_destroy = true
}

# Publicly readable photos so the frontend can render them directly
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.photos.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend service account can write new photos
resource "google_storage_bucket_iam_member" "backend_write" {
  bucket = google_storage_bucket.photos.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.backend_sa.email}"
}
