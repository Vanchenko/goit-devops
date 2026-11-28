# Стейт зберігається в S3, блокування — через DynamoDB.
# Бакет і таблицю створює модуль s3-backend цього ж проєкту,
# тому перший запуск виконується з локальним стейтом — див. README.md.
terraform {
  backend "s3" {
    bucket         = "vanchenko-goit-devops-tfstate"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
