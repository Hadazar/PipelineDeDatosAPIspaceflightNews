variable "vpc_id" {
  type = string
  default = "vpc-0734de6bcbc3cc4ad"
}

variable "s3_vpc_endpoint_route_table_ids" {
  type = list(string)
  default = ["rtb-0f517e7ac6361b2e2"]
}

variable "glue_subnet_id" { #subnet en zona a
  type = string
  default = "subnet-08abb89b2fbb50c4d"
}

variable "glue_availability_zone" {
  type = string
  default = "us-east-1a"
}

variable "mwaa_subnet_ids" {
  type = list(string)
  default = ["subnet-08b5cf982e7405458","subnet-04486298df0c88d52"]
}

variable "api_url" {
  type = string
  default = "https://api.spaceflightnewsapi.net/v4/"
}

variable "articles_endpoint" {
  type = string
  default = "articles/"
}

variable "blogs_endpoint" {
  type = string
  default = "blogs/"
}

variable "info_endpoint" {
  type = string
  default = "info/"
}

variable "reports_endpoint" {
  type = string
  default = "reports/"
}

variable "lbd_articles_name" {
  type = string
  default = "lbd-get-articles"
}

variable "lbd_blogs_name" {
  type = string
  default = "lbd-get-blogs"
}

variable "lbd_info_name" {
  type = string
  default = "lbd-get-info"
}

variable "lbd_reports_name" {
  type = string
  default = "lbd-get-reports"
}

variable "glue_articles_name" {
  type = string
  default = "glue-etl-articles"
}

variable "glue_blogs_name" {
  type = string
  default = "glue-etl-blogs"
}

variable "glue_info_name" {
  type = string
  default = "glue-etl-info"
}

variable "glue_reports_name" {
  type = string
  default = "glue-etl-reports"
}

variable "dag_name" {
  type = string
  default = "pipeline_dag"
}