variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-southeast-2"

}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2
}

variable "enable_monitoring" {
  description = "Enable infrastructure monitoring"
  type        = bool
  default     = false
}
