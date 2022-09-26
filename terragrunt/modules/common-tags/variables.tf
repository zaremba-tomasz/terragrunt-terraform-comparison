variable "environment" {
  type        = string
  description = "The name of an environment"
}

variable "project_name" {
  type        = string
  description = "The name of a project"
}

variable "organisation" {
  type        = string
  description = "The name of an organisation"
  default     = "NearForm"
}
