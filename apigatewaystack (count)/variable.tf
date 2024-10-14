variable "whitelisted_ips" {
  description = "A list of whitelisted IP addresses in CIDR notation"
  type        = list(string)
  default     = ["18.159.214.137/32"] # Example default IPs, you can change these ["18.159.214.137/32", "...", "..."]
}
