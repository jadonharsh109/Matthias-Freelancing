# This resource defines an API Gateway REST API named "HelloWorldAPI".
# This resource defines an API Gateway REST API named "HelloWorldAPI".
resource "aws_api_gateway_rest_api" "MyDemoAPI" {
  name        = "HelloWorldAPI"               # Name of the API
  description = "API Gateway for Hello World" # Description of what the API does

  # Add the endpoint configuration block here to set the type to Regional
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# This resource creates a new resource (like a folder or path) inside the API Gateway.
resource "aws_api_gateway_resource" "HelloWorldResource" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id               # Links to the defined REST API
  parent_id   = aws_api_gateway_rest_api.MyDemoAPI.root_resource_id # Sets the parent to the root of the API
  path_part   = "hello"                                             # Path segment (e.g., /hello)
}

# This resource defines a new HTTP method for the previously defined resource.
resource "aws_api_gateway_method" "HelloWorldMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyDemoAPI.id          # Links to the REST API
  resource_id   = aws_api_gateway_resource.HelloWorldResource.id # Links to the resource
  http_method   = "GET"                                          # HTTP Method
  authorization = "NONE"                                         # No authorization required
}

# Sets up the "backend" integration for the GET method.
resource "aws_api_gateway_integration" "HelloWorldIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id               # Links to the REST API
  resource_id = aws_api_gateway_resource.HelloWorldResource.id      # Links to the resource
  http_method = aws_api_gateway_method.HelloWorldMethod.http_method # HTTP Method from the method definition
  type        = "MOCK"                                              # Type of integration. MOCK means no backend
  request_templates = {
    "application/json" = "{\"statusCode\": 200}" # Template for the request payload (mock integration)
  }
}

# Defines the response format for a 200 status code.
resource "aws_api_gateway_method_response" "status_200" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id               # Links to the REST API
  resource_id = aws_api_gateway_resource.HelloWorldResource.id      # Links to the resource
  http_method = aws_api_gateway_method.HelloWorldMethod.http_method # HTTP Method
  status_code = "200"                                               # Status code to match for this response

  response_models = {
    "application/json" = "Empty" # Response MIME type
  }
}

# Defines the template for the response to be returned for a 200 status code.
resource "aws_api_gateway_integration_response" "status_200" {
  depends_on = [
    aws_api_gateway_integration.HelloWorldIntegration, # Ensuring integration is created first
  ]
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id                  # Links to the REST API
  resource_id = aws_api_gateway_resource.HelloWorldResource.id         # Links to the resource
  http_method = aws_api_gateway_method.HelloWorldMethod.http_method    # HTTP Method
  status_code = aws_api_gateway_method_response.status_200.status_code # Status code to match

  response_templates = {
    "application/json" = "{\"message\": \"Hello Matthias, Good Day!!\"}" # Actual content of the response
  }
}

# Creates a deployment for the API Gateway.
resource "aws_api_gateway_deployment" "HelloWorldDeployment" {
  depends_on = [
    aws_api_gateway_integration_response.status_200 # Depends on the integration response
  ]
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id # Links to the REST API
  stage_name  = "v1"                                  # Stage name (e.g., v1, prod, etc.)
}

# Outputs the URL needed to invoke the API, appending the /hello path.
# output "hello_world_invoke_url" {
#   value = "${aws_api_gateway_deployment.HelloWorldDeployment.invoke_url}/hello"
# }
