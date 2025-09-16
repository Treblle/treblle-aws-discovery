terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "treblle_demo_api" {
  name        = "treblle-demo-api"
  description = "Demo API used for testing and discovery purposes"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Articles resource
resource "aws_api_gateway_resource" "articles" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_rest_api.treblle_demo_api.root_resource_id
  path_part   = "articles"
}

# Articles UUID resource
resource "aws_api_gateway_resource" "articles_uuid" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.articles.id
  path_part   = "{uuid}"
}

# Articles UUID favorite resource
resource "aws_api_gateway_resource" "articles_uuid_favorite" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.articles_uuid.id
  path_part   = "favorite"
}

# Auth resource
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_rest_api.treblle_demo_api.root_resource_id
  path_part   = "auth"
}

# Auth login resource
resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

# Auth register resource
resource "aws_api_gateway_resource" "auth_register" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "register"
}

# Users resource
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_rest_api.treblle_demo_api.root_resource_id
  path_part   = "users"
}

# Users UUID resource
resource "aws_api_gateway_resource" "users_uuid" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{uuid}"
}

# Users UUID favorites resource
resource "aws_api_gateway_resource" "users_uuid_favorites" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  parent_id   = aws_api_gateway_resource.users_uuid.id
  path_part   = "favorites"
}

# POST /articles method
resource "aws_api_gateway_method" "articles_post" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.articles.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET /articles method
resource "aws_api_gateway_method" "articles_get" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.articles.id
  http_method   = "GET"
  authorization = "NONE"
}

# GET /articles/{uuid} method
resource "aws_api_gateway_method" "articles_uuid_get" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.articles_uuid.id
  http_method   = "GET"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.uuid" = true
  }
}

# POST /articles/{uuid}/favorite method
resource "aws_api_gateway_method" "articles_uuid_favorite_post" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.articles_uuid_favorite.id
  http_method   = "POST"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.uuid" = true
  }
}

# POST /auth/login method
resource "aws_api_gateway_method" "auth_login_post" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "NONE"
}

# POST /auth/register method
resource "aws_api_gateway_method" "auth_register_post" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET /users/{uuid} method
resource "aws_api_gateway_method" "users_uuid_get" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.users_uuid.id
  http_method   = "GET"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.uuid" = true
  }
}

# GET /users/{uuid}/favorites method
resource "aws_api_gateway_method" "users_uuid_favorites_get" {
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id   = aws_api_gateway_resource.users_uuid_favorites.id
  http_method   = "GET"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.uuid" = true
  }
}

# HTTP proxy integrations for all methods
resource "aws_api_gateway_integration" "articles_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.articles.id
  http_method             = aws_api_gateway_method.articles_post.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "https://demo.treblle.com/api/v1/articles"
  
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/json'"
  }
}

resource "aws_api_gateway_integration" "articles_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.articles.id
  http_method             = aws_api_gateway_method.articles_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "https://demo.treblle.com/api/v1/articles"
}

resource "aws_api_gateway_integration" "articles_uuid_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.articles_uuid.id
  http_method             = aws_api_gateway_method.articles_uuid_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "https://demo.treblle.com/api/v1/articles/{uuid}"
  
  request_parameters = {
    "integration.request.path.uuid" = "method.request.path.uuid"
  }
}

resource "aws_api_gateway_integration" "articles_uuid_favorite_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.articles_uuid_favorite.id
  http_method             = aws_api_gateway_method.articles_uuid_favorite_post.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "https://demo.treblle.com/api/v1/articles/{uuid}/favorite"
  
  request_parameters = {
    "integration.request.path.uuid"           = "method.request.path.uuid"
    "integration.request.header.Content-Type" = "'application/json'"
  }
}

resource "aws_api_gateway_integration" "auth_login_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.auth_login.id
  http_method             = aws_api_gateway_method.auth_login_post.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "https://demo.treblle.com/api/v1/auth/login"
  
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/json'"
  }
}

resource "aws_api_gateway_integration" "auth_register_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.auth_register.id
  http_method             = aws_api_gateway_method.auth_register_post.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "https://demo.treblle.com/api/v1/auth/register"
  
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/json'"
  }
}

resource "aws_api_gateway_integration" "users_uuid_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.users_uuid.id
  http_method             = aws_api_gateway_method.users_uuid_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "https://demo.treblle.com/api/v1/users/{uuid}"
  
  request_parameters = {
    "integration.request.path.uuid" = "method.request.path.uuid"
  }
}

resource "aws_api_gateway_integration" "users_uuid_favorites_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id             = aws_api_gateway_resource.users_uuid_favorites.id
  http_method             = aws_api_gateway_method.users_uuid_favorites_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "https://demo.treblle.com/api/v1/users/{uuid}/favorites"
  
  request_parameters = {
    "integration.request.path.uuid" = "method.request.path.uuid"
  }
}

# Method responses for all endpoints
resource "aws_api_gateway_method_response" "articles_post_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.articles.id
  http_method = aws_api_gateway_method.articles_post.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "articles_get_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.articles.id
  http_method = aws_api_gateway_method.articles_get.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "articles_uuid_get_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.articles_uuid.id
  http_method = aws_api_gateway_method.articles_uuid_get.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "articles_uuid_favorite_post_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.articles_uuid_favorite.id
  http_method = aws_api_gateway_method.articles_uuid_favorite_post.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "auth_login_post_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.auth_login.id
  http_method = aws_api_gateway_method.auth_login_post.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "auth_register_post_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.auth_register.id
  http_method = aws_api_gateway_method.auth_register_post.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "users_uuid_get_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.users_uuid.id
  http_method = aws_api_gateway_method.users_uuid_get.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "users_uuid_favorites_get_200" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  resource_id = aws_api_gateway_resource.users_uuid_favorites.id
  http_method = aws_api_gateway_method.users_uuid_favorites_get.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}


# API Gateway deployment
resource "aws_api_gateway_deployment" "treblle_demo_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.treblle_demo_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.articles.id,
      aws_api_gateway_resource.articles_uuid.id,
      aws_api_gateway_resource.articles_uuid_favorite.id,
      aws_api_gateway_resource.auth.id,
      aws_api_gateway_resource.auth_login.id,
      aws_api_gateway_resource.auth_register.id,
      aws_api_gateway_resource.users.id,
      aws_api_gateway_resource.users_uuid.id,
      aws_api_gateway_resource.users_uuid_favorites.id,
      aws_api_gateway_method.articles_post.id,
      aws_api_gateway_method.articles_get.id,
      aws_api_gateway_method.articles_uuid_get.id,
      aws_api_gateway_method.articles_uuid_favorite_post.id,
      aws_api_gateway_method.auth_login_post.id,
      aws_api_gateway_method.auth_register_post.id,
      aws_api_gateway_method.users_uuid_get.id,
      aws_api_gateway_method.users_uuid_favorites_get.id,
      aws_api_gateway_integration.articles_post_integration.id,
      aws_api_gateway_integration.articles_get_integration.id,
      aws_api_gateway_integration.articles_uuid_get_integration.id,
      aws_api_gateway_integration.articles_uuid_favorite_post_integration.id,
      aws_api_gateway_integration.auth_login_post_integration.id,
      aws_api_gateway_integration.auth_register_post_integration.id,
      aws_api_gateway_integration.users_uuid_get_integration.id,
      aws_api_gateway_integration.users_uuid_favorites_get_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "treblle_demo_api_stage" {
  deployment_id = aws_api_gateway_deployment.treblle_demo_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.treblle_demo_api.id
  stage_name    = var.stage_name
}

# Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.treblle_demo_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.treblle_demo_api.id
}