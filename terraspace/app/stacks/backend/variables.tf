variable "environment" {
  type        = string
  description = "The name of an environment"
}

variable "tags" {
  type        = map(string)
  description = "The list of tags assigned to created resources"
}
