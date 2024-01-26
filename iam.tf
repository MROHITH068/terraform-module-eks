
resource "aws_iam_role" "eks-role" {
  name               = "eks-cluster-example"
  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "eks.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-role.name
}

resource "aws_iam_role" "node-role" {
  name = "${var.env}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-role.name
}


resource "aws_iam_policy" "sa-policy" {
  name        = "eks-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "eks-${var.env}-ssm-pm-policy"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
            "kms:Decrypt",
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource": [
            "arn:aws:kms:us-east-1:403215663985:key/8dd96880-9b44-4bb8-b1f2-1f5940d93f11",
            "arn:aws:ssm:us-east-1:403215663985:parameter/roboshop.*",
          ]
        },
        {
          "Sid": "VisualEditor1",
          "Effect": "Allow",
          "Action": "ssm:DescribeParameters",
          "Resource": "*"
        }
      ]
    })
}

#Role
resource "aws_iam_role" "sa-role" {
  name = "eks-${var.env}-ssm-pm-role"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": aws_iam_openid_connect_provider.oidc-iam.arn
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.us-east-1.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.oidc-iam.arn), 3)}:aud": ["sts.amazonaws.com"]
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role      = aws_iam_role.sa-role.name
  policy_arn = aws_iam_policy.sa-policy.arn
}
