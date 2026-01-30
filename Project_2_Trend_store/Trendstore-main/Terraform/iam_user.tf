#---------------------------------
# IAM Admin User
#---------------------------------
resource "aws_iam_user" "admin_user" {
  name = "trendstore-admin"

  tags = {
    Project     = local.name
    ManagedBy   = "Terraform"
  }
}

#---------------------------------
# Attach AdministratorAccess
#---------------------------------
resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#---------------------------------
# Attach Billing Access
#---------------------------------
resource "aws_iam_user_policy_attachment" "billing" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

#---------------------------------
# Attach IAM Full Access
# (needed for OIDC Provider + IRSA)
#---------------------------------
resource "aws_iam_user_policy_attachment" "iam_full" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

