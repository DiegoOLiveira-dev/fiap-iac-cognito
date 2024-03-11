resource "aws_cognito_user_pool" "clients_pool" {
  name = "clientes-pool"

  username_configuration {
    case_sensitive = false
  }

  tags = {
    Name = "clients_pool"
  }
}

resource "aws_cognito_user_pool" "admin_pool" {
  name = "admin-pool"

  username_configuration {
    case_sensitive = false
  }

  tags = {
    Name = "admin_pool"
  }
}

resource "aws_cognito_user_pool_client" "clients_pool_client" {
  name = "pool-client"

  user_pool_id = aws_cognito_user_pool.clients_pool.id
}

resource "aws_cognito_user_pool_client" "admin_pool_client" {
  name = "pool-admin"

  user_pool_id = aws_cognito_user_pool.admin_pool.id
}

resource "aws_cognito_identity_pool" "identity_pool_client" {
  identity_pool_name = "example-identity-pool-client"

  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.clients_pool_client.id
    provider_name           = aws_cognito_user_pool.clients_pool.endpoint
    server_side_token_check = false
  }
  
}

resource "aws_cognito_identity_pool" "identity_pool_admin" {
  identity_pool_name = "example-identity-pool-admin"

  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.admin_pool_client.id
    provider_name           = aws_cognito_user_pool.admin_pool.endpoint
    server_side_token_check = false
    
  }
  
}

resource "aws_ssm_parameter" "clients_pool_id" {
  name  = "/pools/client"
  type  = "String"
  value = aws_cognito_user_pool.clients_pool.id
}

resource "aws_ssm_parameter" "clients_pool_client_id" {
  name  = "/pools/client/client"
  type  = "String"
  value = aws_cognito_user_pool_client.clients_pool_client.id
}

resource "aws_ssm_parameter" "admin_pool_id" {
  name  = "/pools/admin"
  type  = "String"
  value = aws_cognito_user_pool.admin_pool.id
}

resource "aws_ssm_parameter" "admin_pool_client_id" {
  name  = "/pools/admin/client"
  type  = "String"
  value = aws_cognito_user_pool_client.admin_pool_client.id
}

resource "aws_ssm_parameter" "identity_pool_client" {
  name  = "/pools/identity/client"
  type  = "String"
  value = aws_cognito_identity_pool.identity_pool_client.id
}

resource "aws_ssm_parameter" "identity_pool_admin" {
  name  = "/pools/identity/admin"
  type  = "String"
  value = aws_cognito_identity_pool.identity_pool_admin.id
}

resource "aws_ssm_parameter" "region" {
  name  = "/pools/identity/region"
  type  = "String"
  value = "us-east-1"
}


resource "aws_iam_policy" "example_policy" {
  name        = "ExamplePolicy"
  description = "Example IAM policy allowing access to Cognito Identity GetCredentialsForIdentity action"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "cognito-identity:GetCredentialsForIdentity"
        Resource = "*"
      }
    ]
  })
}

# resource "aws_iam_role" "example_role" {
#   name               = "ExampleRole"
#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = {
#           Service = "cognito-identity.amazonaws.com"
#         }
#         Action    = "sts:AssumeRoleWithWebIdentity"
#       }
#     ]
#   })
# }

resource "aws_iam_role" "example_role" {
  name               = "ExampleIdentityRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool_client.id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_policy_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = aws_iam_policy.example_policy.arn
}


resource "aws_cognito_identity_pool_roles_attachment" "example_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool_client.id
  roles            = {
    "authenticated" = aws_iam_role.example_role.arn
  }

  depends_on = [ aws_iam_role_policy_attachment.example_policy_attachment, aws_cognito_identity_pool.identity_pool_client  ]
}
