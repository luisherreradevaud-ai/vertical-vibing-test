variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Enable versioning for the bucket"
}

variable "enable_cors" {
  type        = bool
  default     = false
  description = "Enable CORS configuration"
}

variable "cors_allowed_headers" {
  type        = list(string)
  default     = ["*"]
  description = "Allowed headers for CORS"
}

variable "cors_allowed_methods" {
  type        = list(string)
  default     = ["GET", "PUT", "POST"]
  description = "Allowed methods for CORS"
}

variable "cors_allowed_origins" {
  type        = list(string)
  default     = ["*"]
  description = "Allowed origins for CORS (configure per environment)"
}

variable "cors_max_age_seconds" {
  type        = number
  default     = 3000
  description = "Max age for CORS preflight cache"
}

variable "enable_lifecycle_rules" {
  type        = bool
  default     = false
  description = "Enable lifecycle rules"
}

variable "lifecycle_rules" {
  type = list(object({
    id               = string
    enabled          = bool
    transition_days  = optional(number)
    storage_class    = optional(string)
    expiration_days  = optional(number)
  }))
  default     = []
  description = "List of lifecycle rules"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the bucket"
}
