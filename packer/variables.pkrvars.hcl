variable "proxmox_api_url" {
  type    = string
  default = "https://pve.thejfk.ca/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "terraform@pam!main_terraform"
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "ubuntu" # If your base template uses a password
}