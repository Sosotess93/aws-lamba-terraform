variable "myregion" {
  description = "The AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "accountId" {
  description = "The AWS account ID"
  type        = string
}

variable "lambda_function_name" {
  description = "What to name the lambda function"
  type        = string
  default     = "editProductToDatabase"
}

variable "apigateway_name" {
  description = "What to name the Api"
  type        = string
  default     = "Quable-Api_Product_Example"
}

variable "endpoint_path" {
  description = "The GET endpoint path"
  type        = string
  default     = "edit"
}
