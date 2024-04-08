variable "myregion" {
  description = "The AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "accountId" {
  description = "The AWS account ID"
  type        = string
}

variable "lambda_function_name_edit_product" {
  description = "What to name the lambda function"
  type        = string
  default     = "editQuableProductDatabaseLambda"
}

variable "lambda_function_name_create_product" {
  description = "What to name the lambda function"
  type        = string
  default     = "createQuableProductDatabaseLambda"
}

variable "apigateway_name" {
  description = "What to name the Api"
  type        = string
  default     = "Quable-Api_Product_Example"
}

variable "endpoint_path" {
  description = "The GET endpoint path"
  type        = string
  default     = "product"
}

variable "endpoint_edit_product" {
  description = "The GET endpoint path"
  type        = string
  default     = "edit"
}

variable "endpoint_create_product" {
  description = "The GET endpoint path"
  type        = string
  default     = "edit"
}
