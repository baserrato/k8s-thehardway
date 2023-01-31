variable "client-secret" {
  type      = string
  default   = null
  sensitive = true
}

variable "tenant-id" {
  type      = string
  default   = null
  sensitive = true
}

variable "client-id" {
  type      = string
  default   = null
  sensitive = true
}

variable "subscription-id" {
  type      = string
  default   = null
  sensitive = true
}

variable "controller-count" {
  type    = number
  default = 0
}

variable "worker-count" {
  type    = number
  default = 0
}
