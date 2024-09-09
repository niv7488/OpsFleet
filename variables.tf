variable "cluster_name" {
  type        = string
  default     = "my-eks-cluster"
}

variable "subnet_ids" {
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  type        = list(string)
}