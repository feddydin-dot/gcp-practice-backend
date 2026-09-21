variable "cloudrun_name" {
  default = "practice-backend"
}
variable "cloudrun_ingress" {
  default = "INGRESS_TRAFFIC_ALL"
}

variable "cloudrun_image" {
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "project_id" {
  default = "practice-frontend-508908"
}