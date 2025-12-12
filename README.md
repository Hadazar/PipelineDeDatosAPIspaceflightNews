# 📡 Spaceflight News Data Pipeline  
🚀 **Un pipeline de datos en AWS para analizar tendencias en la industria espacial**  

Este repositorio contiene la implementación de un **pipeline de datos** que extrae información desde la API de **Spaceflight News**, la transforma y la almacena en **Amazon Redshift** para su análisis.  

---

## 🔹 Tecnologías principales  

- **Apache Airflow** (Orquestación del pipeline)  
- **AWS Lambda** (Ingesta de datos desde la API)  
- **Amazon S3** (Almacenamiento de datos en crudo)  
- **AWS Glue** (Procesamiento ETL)  
- **Amazon Redshift** (Almacenamiento estructurado y consultas SQL)  
- **Terraform** (Infraestructura como código - IaC)  

---

## ⚙️ Requisitos Previos  

Antes de ejecutar este pipeline, asegúrate de tener:  

- 🔹 **AWS CLI** configurado con permisos para crear y administrar todos los componentes.  
- 🔹 **Terraform** instalado para desplegar la infraestructura en AWS.  

---

## 1️⃣ Desplegar la Infraestructura con Terraform  

📌 **Ajustar las variables en `iac_variables.tf`** para que correspondan con la cuenta AWS en la que se desplegará el pipeline.  

Desde la carpeta `iac`, ejecutar:  

```bash
terraform init
terraform apply
