output "bucket_name" {
  value = google_storage_bucket.photos.name
}

output "db_instance_connection_name" {
  value = google_sql_database_instance.instance.connection_name
}
