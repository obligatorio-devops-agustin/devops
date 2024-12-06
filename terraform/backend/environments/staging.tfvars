environment          = "staging"
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
dockerhub_username   = "agusmartinez62"
services             = ["orders", "products", "payments", "shipping"]
api_gateway_name     = "backend-api-staging"
api_routes = [
  { method = "GET", path = "/orders/health" },
  { method = "POST", path = "/orders" },
  { method = "GET", path = "/payments/health" },
  { method = "POST", path = "/payments/{id}" },
  { method = "GET", path = "/products/health" },
  { method = "GET",  path = "/products" },
  { method = "GET",  path = "/products/{id}" },
  { method = "GET",  path = "/shipping/health" },
  { method = "POST", path = "/shipping/{id}" },
  { method = "GET",  path = "/shipping/{id}" },
]