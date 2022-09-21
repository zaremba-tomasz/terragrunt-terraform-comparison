variable "environment" {
  type        = string
  description = "The name of an environment"
}

variable "stack" {
  type        = string
  description = "The name of a stack"
}

variable "project" {
  type        = string
  description = "The name of a project"
}

variable "organisation" {
  type        = string
  description = "The name of an organisation"
  default     = "NearForm"
}
