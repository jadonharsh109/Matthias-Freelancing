variable "callback_url" {
  description = "The callback URL after the user signs in"
  type        = string
  default     = "https://oauth.pstmn.io/v1/callback"
}

variable "signout_url" {
  description = "The Signout URL after the user loged out"
  type        = string
  default     = "https://oauth.pstmn.io/v1/logout"
}
