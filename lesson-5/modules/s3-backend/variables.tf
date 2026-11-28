variable "bucket_name" {
  description = "Ім'я S3-бакета для стейтів (унікальне в межах усього AWS, лише малі літери, цифри та дефіси)"
  type        = string
}

variable "table_name" {
  description = "Ім'я таблиці DynamoDB для блокування стейтів"
  type        = string
  default     = "terraform-locks"
}

variable "force_destroy" {
  description = "Дозволити видалення бакета разом з усіма об'єктами при terraform destroy"
  type        = bool
  default     = true
}
