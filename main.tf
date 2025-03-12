# AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "api_lambda_role"

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

# Archive for GET Lambda
data "archive_file" "get_lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/get"
  output_path = "${path.module}/get_method.zip"
}

# Archive for POST Lambda
data "archive_file" "post_lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/post"
  output_path = "${path.module}/post_method.zip"
}

# IAM Policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "OUTPUT" {
  value = data.archive_file.get_lambda_zip.output_path
}

resource "aws_lambda_function" "get_lambda" {
  function_name    = "api_get_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.9"

  source_code_hash = data.archive_file.get_lambda_zip.output_base64sha256
  filename         = data.archive_file.get_lambda_zip.output_path

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

resource "aws_lambda_function" "post_lambda" {
  filename         = data.archive_file.post_lambda_zip.output_path
  function_name    = "api_post_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.post_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENV = "dev"
    }
  }
}
# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "test_api"
  description = "Test API Gateway with GET and POST endpoints"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "test"
}

# API Gateway Method for GET
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration for GET
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_lambda.invoke_arn
}

# API Gateway Method for POST
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration for POST
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_lambda.invoke_arn
}

# Lambda permission for API Gateway to invoke GET Lambda
resource "aws_lambda_permission" "get_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke POST Lambda
resource "aws_lambda_permission" "post_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
}

# Output the API Gateway URL
output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/${aws_api_gateway_resource.resource.path_part}"
}