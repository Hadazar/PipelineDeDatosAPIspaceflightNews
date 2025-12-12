#################################################################
# IAC PIPELINE DE DATOS PARA CONSUMIR LA API DE SPACE FLIGHT NEWS
#################################################################

#################################################################
# BUCKET PARA ALMACENAR CODIGO FUENTE

resource "aws_s3_bucket" "s3_code_tf" {
  bucket = "s3-spaceflight-news-code"
}

resource "aws_s3_object" "s3o_glue_etl_articles_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.glue_articles_name}.py"
  source = "${path.module}/../glues/${var.glue_articles_name}.py"
  etag   = filemd5("${path.module}/../glues/${var.glue_articles_name}.py")
}

resource "aws_s3_object" "s3o_glue_etl_blogs_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.glue_blogs_name}.py"
  source = "${path.module}/../glues/${var.glue_blogs_name}.py"
  etag   = filemd5("${path.module}/../glues/${var.glue_blogs_name}.py")
}

resource "aws_s3_object" "s3o_glue_etl_reports_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.glue_reports_name}.py"
  source = "${path.module}/../glues/${var.glue_reports_name}.py"
  etag   = filemd5("${path.module}/../glues/${var.glue_reports_name}.py")
}

resource "aws_s3_object" "s3o_glue_etl_info_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.glue_info_name}.py"
  source = "${path.module}/../glues/${var.glue_info_name}.py"
  etag   = filemd5("${path.module}/../glues/${var.glue_info_name}.py")
}

resource "aws_s3_object" "s3o_dag_pipeline_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.dag_name}.py"
  source = "${path.module}/../dags/${var.dag_name}.py"
  etag   = filemd5("${path.module}/../dags/${var.dag_name}.py")
}

resource "aws_s3_object" "s3o_nlkt_files_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "nltk_data.tar.gz"
  source = "nltk_data.tar.gz"
  etag   = filemd5("nltk_data.tar.gz")
}

resource "aws_s3_object" "s3o_jdbc_redshift_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "redshift-jdbc42-2.1.0.32.jar"
  source = "redshift-jdbc42-2.1.0.32.jar"
  etag   = filemd5("redshift-jdbc42-2.1.0.32.jar")
}

#################################################################
# BUCKET PARA ALMACENAR LOS DATOS CRUDOS

resource "aws_s3_bucket" "s3_raw_data_tf" {
  bucket = "s3-spaceflight-news-raw"
}

resource "aws_s3_object" "s3o_articles_folder_tf" {
  bucket = aws_s3_bucket.s3_raw_data_tf.id
  key    = "articles/"
}

resource "aws_s3_object" "s3o_reports_folder_tf" {
  bucket = aws_s3_bucket.s3_raw_data_tf.id
  key    = "reports/"
}

resource "aws_s3_object" "s3o_info_folder_tf" {
  bucket = aws_s3_bucket.s3_raw_data_tf.id
  key    = "info/"
}

resource "aws_s3_object" "s3o_blogs_folder_tf" {
  bucket = aws_s3_bucket.s3_raw_data_tf.id
  key    = "blogs/"
}

resource "aws_s3_object" "s3o_temp_folder_tf" {
  bucket = aws_s3_bucket.s3_raw_data_tf.id
  key    = "tmp/"
}

#################################################################
# ROLE PARA EL LAMBDA DE ARTICULOS

resource "aws_iam_role" "ir_lbd_get_articles_tf" {
  name = "role-${var.lbd_articles_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

#################################################################
# POLITICA PARA EL LAMBDA DE ARTICULOS

resource "aws_iam_role_policy" "irp_lbd_get_articles_tf" {
  name = "policy-${var.lbd_articles_name}"
  role = aws_iam_role.ir_lbd_get_articles_tf.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_raw_data_tf.arn}/*"
        ]
      },
    ]
  })
}

###############################################################################
# CODIGO FUENTE DEL LAMBDA DE ARTICULOS

data "archive_file" "af_lbd_get_articles_tf" {
  type        = "zip"
  source_file = "${path.module}/../lbds/${var.lbd_articles_name}.py"
  output_path = "${var.lbd_articles_name}.zip"
}

resource "aws_s3_object" "s3o_lbd_get_articles_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.lbd_articles_name}.zip"
  source = data.archive_file.af_lbd_get_articles_tf.output_path
  etag   = filemd5(data.archive_file.af_lbd_get_articles_tf.output_path)
}

#################################################################
# CAPA REQUESTS PARA LOS LAMBDAS

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "requests-lambda-layer.zip"
  layer_name = "requests-lambda-layer"

  compatible_runtimes = ["python3.9"]
}

#################################################################
# LAMBDA PARA CONSUMIR EL ENDPOINT DE ARTICULOS

resource "aws_lambda_function" "lbd_get_articles_tf" {
  s3_bucket        = aws_s3_bucket.s3_code_tf.id
  s3_key           = aws_s3_object.s3o_lbd_get_articles_tf.key
  source_code_hash = data.archive_file.af_lbd_get_articles_tf.output_base64sha256
  function_name    = var.lbd_articles_name
  role             = aws_iam_role.ir_lbd_get_articles_tf.arn
  handler          = "${var.lbd_articles_name}.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  environment {
    variables = {
      BASE_URL                 = "${var.api_url}${var.articles_endpoint}"
      S3_BUCKET                = aws_s3_bucket.s3_raw_data_tf.id
      AMOUNT_ARTICLES_FOR_FILE = 500
      MAX_RETRIES              = 5
    }
  }
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

#################################################################
# ROLE PARA EL LAMBDA DE BLOGS

resource "aws_iam_role" "ir_lbd_get_blogs_tf" {
  name = "role-${var.lbd_blogs_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

#################################################################
# POLITICA PARA EL LAMBDA DE BLOGS

resource "aws_iam_role_policy" "irp_lbd_get_blogs_tf" {
  name = "policy-${var.lbd_blogs_name}"
  role = aws_iam_role.ir_lbd_get_blogs_tf.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_raw_data_tf.arn}/*"
        ]
      },
    ]
  })
}

###############################################################################
# CODIGO FUENTE DEL LAMBDA DE BLOGS

data "archive_file" "af_lbd_get_blogs_tf" {
  type        = "zip"
  source_file = "${path.module}/../lbds/${var.lbd_blogs_name}.py"
  output_path = "${var.lbd_blogs_name}.zip"
}

resource "aws_s3_object" "s3o_lbd_get_blogs_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.lbd_blogs_name}.zip"
  source = data.archive_file.af_lbd_get_blogs_tf.output_path
  etag   = filemd5(data.archive_file.af_lbd_get_blogs_tf.output_path)
}

#################################################################
# LAMBDA PARA CONSUMIR EL ENDPOINT DE BLOGS

resource "aws_lambda_function" "lbd_get_blogs_tf" {
  s3_bucket        = aws_s3_bucket.s3_code_tf.id
  s3_key           = aws_s3_object.s3o_lbd_get_blogs_tf.key
  source_code_hash = data.archive_file.af_lbd_get_blogs_tf.output_base64sha256
  function_name    = var.lbd_blogs_name
  role             = aws_iam_role.ir_lbd_get_blogs_tf.arn
  handler          = "${var.lbd_blogs_name}.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  environment {
    variables = {
      BASE_URL                 = "${var.api_url}${var.blogs_endpoint}"
      S3_BUCKET                = aws_s3_bucket.s3_raw_data_tf.id
      AMOUNT_ARTICLES_FOR_FILE = 500
      MAX_RETRIES              = 5
    }
  }
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

#################################################################
# ROLE PARA EL LAMBDA DE REPORTS

resource "aws_iam_role" "ir_lbd_get_reports_tf" {
  name = "role-${var.lbd_reports_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

#################################################################
# POLITICA PARA EL LAMBDA DE REPORTS

resource "aws_iam_role_policy" "irp_lbd_get_reports_tf" {
  name = "policy-${var.lbd_reports_name}"
  role = aws_iam_role.ir_lbd_get_reports_tf.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_raw_data_tf.arn}/*"
        ]
      },
    ]
  })
}

###############################################################################
# CODIGO FUENTE DEL LAMBDA DE REPORTS

data "archive_file" "af_lbd_get_reports_tf" {
  type        = "zip"
  source_file = "${path.module}/../lbds/${var.lbd_reports_name}.py"
  output_path = "${var.lbd_reports_name}.zip"
}

resource "aws_s3_object" "s3o_lbd_get_reports_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.lbd_reports_name}.zip"
  source = data.archive_file.af_lbd_get_reports_tf.output_path
  etag   = filemd5(data.archive_file.af_lbd_get_reports_tf.output_path)
}

#################################################################
# LAMBDA PARA CONSUMIR EL ENDPOINT DE REPORTS

resource "aws_lambda_function" "lbd_get_reports_tf" {
  s3_bucket        = aws_s3_bucket.s3_code_tf.id
  s3_key           = aws_s3_object.s3o_lbd_get_reports_tf.key
  source_code_hash = data.archive_file.af_lbd_get_reports_tf.output_base64sha256
  function_name    = var.lbd_reports_name
  role             = aws_iam_role.ir_lbd_get_reports_tf.arn
  handler          = "${var.lbd_reports_name}.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  environment {
    variables = {
      BASE_URL                 = "${var.api_url}${var.reports_endpoint}"
      S3_BUCKET                = aws_s3_bucket.s3_raw_data_tf.id
      AMOUNT_ARTICLES_FOR_FILE = 500
      MAX_RETRIES              = 5
    }
  }
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

#################################################################
# ROLE PARA EL LAMBDA DE INFO

resource "aws_iam_role" "ir_lbd_get_info_tf" {
  name = "role-${var.lbd_info_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

#################################################################
# POLITICA PARA EL LAMBDA DE INFO

resource "aws_iam_role_policy" "irp_lbd_get_info_tf" {
  name = "policy-${var.lbd_info_name}"
  role = aws_iam_role.ir_lbd_get_info_tf.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_raw_data_tf.arn}/*"
        ]
      },
    ]
  })
}

###############################################################################
# CODIGO FUENTE DEL LAMBDA DE INFO

data "archive_file" "af_lbd_get_info_tf" {
  type        = "zip"
  source_file = "${path.module}/../lbds/${var.lbd_info_name}.py"
  output_path = "${var.lbd_info_name}.zip"
}

resource "aws_s3_object" "s3o_lbd_get_info_tf" {
  bucket = aws_s3_bucket.s3_code_tf.id
  key    = "${var.lbd_info_name}.zip"
  source = data.archive_file.af_lbd_get_info_tf.output_path
  etag   = filemd5(data.archive_file.af_lbd_get_info_tf.output_path)
}

#################################################################
# LAMBDA PARA CONSUMIR EL ENDPOINT DE INFO

resource "aws_lambda_function" "lbd_get_info_tf" {
  s3_bucket        = aws_s3_bucket.s3_code_tf.id
  s3_key           = aws_s3_object.s3o_lbd_get_info_tf.key
  source_code_hash = data.archive_file.af_lbd_get_info_tf.output_base64sha256
  function_name    = var.lbd_info_name
  role             = aws_iam_role.ir_lbd_get_info_tf.arn
  handler          = "${var.lbd_info_name}.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  environment {
    variables = {
      BASE_URL                 = "${var.api_url}${var.info_endpoint}"
      S3_BUCKET                = aws_s3_bucket.s3_raw_data_tf.id
      AMOUNT_ARTICLES_FOR_FILE = 500
      MAX_RETRIES              = 5
    }
  }
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

#################################################################
# ROLE PARA REDSHIFT

resource "aws_iam_role" "redshift_role" {
  name = "role-redshift-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
}


#################################################################
# CLUSTER REDSHIFT

resource "aws_redshift_cluster" "rc_datawarehouse_tf" {
  cluster_identifier  = "rc-spaceflight-datawarehouse"
  database_name       = "space_flight"
  master_username     = "admin"
  master_password     = "Mustbe8characters"
  node_type           = "dc2.large"
  cluster_type        = "single-node"
  publicly_accessible = false
  skip_final_snapshot = true
  encrypted           = true
}

resource "aws_redshift_cluster_iam_roles" "redshift_role_attachment" {
  cluster_identifier = aws_redshift_cluster.rc_datawarehouse_tf.id
  iam_role_arns      = [aws_iam_role.redshift_role.arn]
}


#################################################################
# ROL PARA GLUE QUE PROCESARA LOS DATOS DE ARTICULOS

resource "aws_iam_role" "ir_glues_etl_tf" {
  name = "role-${var.glue_articles_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}

#################################################################
# POLITICAS PARA GLUE QUE PROCESARA LOS DATOS DE ARTICULOS

resource "aws_iam_role_policy_attachment" "irpa_glues_etl_tf" {
  role       = aws_iam_role.ir_glues_etl_tf.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "redshift_all_for_glue_policy" {
  role       = aws_iam_role.ir_glues_etl_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy" "irp_glues_etl_tf" {
  role = aws_iam_role.ir_glues_etl_tf.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject", "s3:GetObject", "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.s3_raw_data_tf.arn}/*", "${aws_s3_bucket.s3_code_tf.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["redshift:GetClusterCredentials", "redshift:DescribeClusters"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["redshift-data:ExecuteStatement", "redshift-data:GetStatementResult"]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      }

    ]
  })
}

#################################################################
# GLUE QUE PROCESARA LOS DATOS DE ARTICULOS

resource "aws_glue_job" "glue_etl_articles_tf" {
  name     = var.glue_articles_name
  role_arn = aws_iam_role.ir_glues_etl_tf.arn
  command {
    script_location = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${var.glue_articles_name}.py"
    python_version  = "3"
  }
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "false"
    "--extra-jars"                       = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${aws_s3_object.s3o_jdbc_redshift_tf.key}"
  }
  max_retries       = 0
  timeout           = 20
  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  connections       = [aws_glue_connection.glue_network_connection_tf.name]
}

#################################################################
# GLUE QUE PROCESARA LOS DATOS DE BLOGS

resource "aws_glue_job" "glue_etl_blogs_tf" {
  name     = var.glue_blogs_name
  role_arn = aws_iam_role.ir_glues_etl_tf.arn
  command {
    script_location = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${var.glue_blogs_name}.py"
    python_version  = "3"
  }
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "false"
    "--extra-jars"                       = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${aws_s3_object.s3o_jdbc_redshift_tf.key}"
  }
  max_retries       = 0
  timeout           = 20
  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  connections       = [aws_glue_connection.glue_network_connection_tf.name, aws_glue_connection.glue_redshift_connection_tf.name]
}

#################################################################
# GLUE QUE PROCESARA LOS DATOS DE REPORTS

resource "aws_glue_job" "glue_etl_reports_tf" {
  name     = var.glue_reports_name
  role_arn = aws_iam_role.ir_glues_etl_tf.arn
  command {
    script_location = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${var.glue_reports_name}.py"
    python_version  = "3"
  }
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "false"
    "--extra-jars"                       = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${aws_s3_object.s3o_jdbc_redshift_tf.key}"
  }
  max_retries       = 0
  timeout           = 20
  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  connections       = [aws_glue_connection.glue_network_connection_tf.name]
}

#################################################################
# GLUE QUE PROCESARA LOS DATOS DE INFO

resource "aws_glue_job" "glue_etl_info_tf" {
  name     = var.glue_info_name
  role_arn = aws_iam_role.ir_glues_etl_tf.arn
  command {
    script_location = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${var.glue_info_name}.py"
    python_version  = "3"
  }
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "false"
    "--extra-jars"                       = "s3://${aws_s3_bucket.s3_code_tf.bucket}/${aws_s3_object.s3o_jdbc_redshift_tf.key}"
  }
  max_retries       = 0
  timeout           = 5
  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  connections       = [aws_glue_connection.glue_network_connection_tf.name, aws_glue_connection.glue_redshift_connection_tf.name]
}

#################################################################
# CONEXION DE GLUES PARA SU ASIGANCION DE IP DENTRO DE LA PVC

resource "aws_glue_connection" "glue_network_connection_tf" {
  name = "glue-network-connection"
  physical_connection_requirements {
    availability_zone      = var.glue_availability_zone
    security_group_id_list = aws_redshift_cluster.rc_datawarehouse_tf.vpc_security_group_ids
    subnet_id              = var.glue_subnet_id
  }
  connection_type = "NETWORK"
}

resource "aws_glue_connection" "glue_redshift_connection_tf" {
  name = "redshift-glue-connection"

  connection_properties = {
    "JDBC_CONNECTION_URL" = "${aws_redshift_cluster.rc_datawarehouse_tf.endpoint}/space_flight"
    "USERNAME"            = "admin"
    "PASSWORD"            = "Mustbe8characters"
  }

  physical_connection_requirements {
    availability_zone      = var.glue_availability_zone
    security_group_id_list = aws_redshift_cluster.rc_datawarehouse_tf.vpc_security_group_ids
    subnet_id              = var.glue_subnet_id
  }
}

#################################################################
# VPC ENDPOINT PARA S3

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.s3_vpc_endpoint_route_table_ids
  tags = {
    Name = "s3-vpc-endpoint"
  }
}

#################################################################
# AIRFLOW

/* resource "aws_iam_role" "mwaa_role" {
  name = "MWAAFullAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "airflow.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "mwaa_extra_policy" {
  name        = "MWAAExtraPermissions"
  description = "Permisos totales para MWAA"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mwaa_extra" {
  role       = aws_iam_role.mwaa_role.name
  policy_arn = aws_iam_policy.mwaa_extra_policy.arn
}

resource "aws_mwaa_environment" "mwaa_env" {
  dag_s3_path        = "dags/"
  execution_role_arn = aws_iam_role.mwaa_role.arn
  name               = "airflow_environment"

  network_configuration {
    security_group_ids = aws_redshift_cluster.rc_datawarehouse_tf.vpc_security_group_ids
    subnet_ids         = var.mwaa_subnet_ids
  }

  source_bucket_arn = aws_s3_bucket.s3_raw_data_tf.arn
} */
