terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.47.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_lambda_function" "edit_product_lambda" {
  function_name = var.lambda_function_name_edit_product
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"
  filename      = "my-deployment-package.zip"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.edit_product,
  ]
}

resource "aws_lambda_function" "create_product_lambda" {
  function_name = var.lambda_function_name_create_product
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"
  filename      = "my-deployment-package.zip"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.create_product,
  ]
}


resource "aws_cloudwatch_log_group" "edit_product" {
  name              = "/aws/lambda/${var.lambda_function_name_edit_product}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "create_product" {
  name              = "/aws/lambda/${var.lambda_function_name_create_product}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Name of the API
resource "aws_api_gateway_rest_api" "quable_product_api" {
  name = var.apigateway_name
}

# Creating the /product/ ressource (PARENT)
resource "aws_api_gateway_resource" "product_ressource" {
  rest_api_id = aws_api_gateway_rest_api.quable_product_api.id
  parent_id   = aws_api_gateway_rest_api.quable_product_api.root_resource_id
  path_part   = var.endpoint_path
}

# Creating the /product/edit ressource (CHILD EDIT)
resource "aws_api_gateway_resource" "edit_product_ressource" {
  depends_on = [aws_api_gateway_resource.product_ressource]
  rest_api_id = aws_api_gateway_rest_api.quable_product_api.id
  parent_id   = aws_api_gateway_resource.product_ressource.id
  path_part   = var.endpoint_edit_product
}
# Creating the /product/create ressource (CHILD CREATE)
resource "aws_api_gateway_resource" "create_product_ressource" {
  depends_on = [aws_api_gateway_resource.product_ressource]
  rest_api_id = aws_api_gateway_rest_api.quable_product_api.id
  parent_id   = aws_api_gateway_resource.product_ressource.id
  path_part   = var.endpoint_create_product
}

# Creating the POST /product/edit method (CHILD EDIT)
resource "aws_api_gateway_method" "edit_product_method" {
  rest_api_id   = aws_api_gateway_rest_api.quable_product_api.id
  resource_id   = aws_api_gateway_resource.edit_product_ressource.id  # Use the resource_id of edit_product_ressource (/product/edit)
  http_method   = "POST"
  authorization = "NONE"
}

# Creating the POST /product/create method (CHILD CREATE)
resource "aws_api_gateway_method" "create_product_method" {
  rest_api_id   = aws_api_gateway_rest_api.quable_product_api.id
  resource_id   = aws_api_gateway_resource.create_product_ressource.id  # Use the resource_id of edit_product_ressource (/product/edit)
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration for create_product_method
resource "aws_api_gateway_integration" "create_product_integration" {
  rest_api_id             = aws_api_gateway_rest_api.quable_product_api.id
  resource_id             = aws_api_gateway_resource.create_product_ressource.id
  http_method             = aws_api_gateway_method.create_product_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_product_lambda.invoke_arn
}

# API Gateway Integration for edit_product_method
resource "aws_api_gateway_integration" "edit_product_integration" {
  rest_api_id             = aws_api_gateway_rest_api.quable_product_api.id
  resource_id             = aws_api_gateway_resource.edit_product_ressource.id
  http_method             = aws_api_gateway_method.edit_product_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.edit_product_lambda.invoke_arn
}

# Lambda permission for create_product_lambda
resource "aws_lambda_permission" "create_product_permission" {
  statement_id  = "AllowAPIGatewayInvokeCreateProductLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_product_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.quable_product_api.execution_arn}/*/POST/product/create"
}

# Lambda permission for edit_product_lambda
resource "aws_lambda_permission" "edit_product_permission" {
  statement_id  = "AllowAPIGatewayInvokeEditProductLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.edit_product_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.quable_product_api.execution_arn}/*/POST/product/edit"
}

resource "aws_api_gateway_deployment" "quable_api" {
  rest_api_id = aws_api_gateway_rest_api.quable_product_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.quable_product_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.edit_product_method,
    aws_api_gateway_method.create_product_method,
    aws_api_gateway_integration.edit_product_integration,
    aws_api_gateway_integration.create_product_integration,
  ]
}

resource "aws_api_gateway_stage" "quable_api" {
  deployment_id = aws_api_gateway_deployment.quable_api.id
  rest_api_id   = aws_api_gateway_rest_api.quable_product_api.id
  stage_name    = "dev"
}