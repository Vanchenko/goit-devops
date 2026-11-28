# Таблиця DynamoDB для блокування стейтів (state locking).
# Terraform записує сюди запис із ключем LockID на час виконання plan/apply,
# щоб двоє людей не змінювали інфраструктуру одночасно.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.table_name
  }
}
