# lesson-5 — Terraform: S3-бекенд, VPC, ECR в AWS

Terraform-проєкт, який створює в AWS (регіон `us-west-2`):

- **S3-бакет + таблицю DynamoDB** для віддаленого зберігання та блокування стейтів Terraform;
- **VPC** з 3 публічними і 3 приватними підмережами, Internet Gateway, NAT Gateway і таблицями маршрутизації;
- **ECR-репозиторій** для Docker-образів зі скануванням при push.

## Структура проєкту

```
lesson-5/
├── main.tf                 # провайдер AWS і підключення модулів
├── backend.tf              # бекенд: стейт у S3, блокування в DynamoDB
├── outputs.tf              # загальні виведення з усіх модулів
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf           # бакет, версіювання, шифрування, блокування публічного доступу
│   │   ├── dynamodb.tf     # таблиця terraform-locks
│   │   ├── variables.tf
│   │   └── outputs.tf      # URL бакета, ім'я таблиці
│   ├── vpc/
│   │   ├── vpc.tf          # VPC, підмережі, Internet Gateway, Elastic IP, NAT Gateway
│   │   ├── routes.tf       # таблиці маршрутизації та їх прив'язка до підмереж
│   │   ├── variables.tf
│   │   └── outputs.tf      # ID VPC, підмереж, шлюзів
│   └── ecr/
│       ├── ecr.tf          # репозиторій, політика доступу, lifecycle-політика
│       ├── variables.tf
│       └── outputs.tf      # URL репозиторію
└── README.md
```

## Модулі

### s3-backend

Створює інфраструктуру для зберігання стейтів Terraform:

| Ресурс | Призначення |
|---|---|
| `aws_s3_bucket` | бакет для стейт-файлів |
| `aws_s3_bucket_versioning` | версіювання — історія всіх версій стейту, можна відкотитися |
| `aws_s3_bucket_server_side_encryption_configuration` | шифрування AES-256 |
| `aws_s3_bucket_public_access_block` | повна заборона публічного доступу (стейт може містити секрети) |
| `aws_s3_bucket_ownership_controls` | вимкнені ACL, власник об'єктів — власник бакета |
| `aws_dynamodb_table` | таблиця з ключем `LockID` для блокування стейту, режим оплати PAY_PER_REQUEST |

Вхідні змінні: `bucket_name`, `table_name`, `force_destroy`.
Виведення: `s3_bucket_name`, `s3_bucket_url`, `s3_bucket_arn`, `dynamodb_table_name`, `dynamodb_table_arn`.

### vpc

Мережева інфраструктура:

| Ресурс | Призначення |
|---|---|
| `aws_vpc` | VPC `10.0.0.0/16` з увімкненим DNS |
| `aws_subnet.public` ×3 | публічні підмережі `10.0.1-3.0/24` у зонах `us-west-2a/b/c`, з автопризначенням публічних IP |
| `aws_subnet.private` ×3 | приватні підмережі `10.0.4-6.0/24` у тих самих зонах |
| `aws_internet_gateway` | вихід в інтернет для публічних підмереж |
| `aws_eip` + `aws_nat_gateway` | NAT у першій публічній підмережі — вихідний інтернет для приватних підмереж |
| `aws_route_table` ×2 | публічна: `0.0.0.0/0 → IGW`; приватна: `0.0.0.0/0 → NAT` |
| `aws_route_table_association` ×6 | прив'язка кожної підмережі до своєї таблиці |

Використовується один NAT Gateway на всю VPC — це дешевше для навчального проєкту.
У продакшні зазвичай створюють NAT у кожній зоні доступності для відмовостійкості.

Вхідні змінні: `vpc_cidr_block`, `public_subnets`, `private_subnets`, `availability_zones`, `vpc_name`.
Виведення: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `nat_gateway_id`,
`nat_public_ip`, ID таблиць маршрутизації.

### ecr

Реєстр Docker-образів:

| Ресурс | Призначення |
|---|---|
| `aws_ecr_repository` | репозиторій `lesson-5-ecr`, сканування на вразливості при push, шифрування AES-256 |
| `aws_ecr_repository_policy` | політика доступу: push/pull дозволені лише в межах поточного облікового запису AWS |
| `aws_ecr_lifecycle_policy` | зберігаються лише 10 останніх образів |

Вхідні змінні: `ecr_name`, `scan_on_push`, `image_tag_mutability`, `force_delete`, `max_image_count`.
Виведення: `repository_url`, `repository_arn`, `repository_name`.

## Передумови

- Terraform ≥ 1.5 і AWS CLI v2;
- налаштовані облікові дані AWS (`aws configure`) з правами на S3, DynamoDB, EC2/VPC та ECR;
- ім'я бакета в `main.tf` і `backend.tf` має бути унікальним в усьому AWS — за потреби змініть його в обох файлах.

## Запуск

Бакет і таблицю для бекенду створює цей самий проєкт, тож до першого `apply` їх ще не існує.
Тому перший запуск виконується з локальним стейтом, а потім стейт переноситься в S3.

### 1. Перший запуск (бекенд вимкнено)

```bash
cd lesson-5
mv backend.tf backend.tf.disabled   # тимчасово вимикаємо S3-бекенд

terraform init                      # завантажує провайдер AWS
terraform plan                      # показує, що буде створено
terraform apply                     # створює ресурси (підтвердити: yes)
```

### 2. Перенесення стейту в S3

```bash
mv backend.tf.disabled backend.tf   # вмикаємо S3-бекенд
terraform init -migrate-state       # переносить локальний стейт у S3 (підтвердити: yes)
```

Після цього стейт зберігається у `s3://<bucket>/lesson-5/terraform.tfstate`,
а під час `plan`/`apply` в таблиці `terraform-locks` з'являється запис-блокування.

### 3. Подальша робота

```bash
terraform plan
terraform apply
terraform output                    # показати URL бакета, ID VPC, URL ECR тощо
```

## Видалення інфраструктури

> ⚠️ NAT Gateway та Elastic IP оплачуються погодинно. Видаляйте ресурси одразу після перевірки.

`terraform destroy` видаляє і S3-бакет, у якому зберігається стейт. Щоб Terraform не втратив стейт
посеред видалення, спочатку повертаємо його локально:

```bash
mv backend.tf backend.tf.disabled   # вимикаємо S3-бекенд
terraform init -migrate-state       # копіює стейт із S3 у локальний файл (підтвердити: yes)
terraform destroy                   # видаляє всі ресурси (підтвердити: yes)
mv backend.tf.disabled backend.tf   # повертаємо backend.tf на місце
```

Для повторного розгортання — знову виконайте кроки 1–2 розділу «Запуск».

## Примітки

- У Terraform 1.11+ параметр `dynamodb_table` бекенду позначено як застарілий
  (рекомендовано `use_lockfile = true` — блокування через файл у самому S3).
  Він повністю працює; тут використано DynamoDB, як вимагає завдання.
- Локальні файли стейту (`*.tfstate`) і каталог `.terraform/` додано в `.gitignore`.
  Файл `.terraform.lock.hcl`, який створює `terraform init`, варто закомітити —
  він фіксує версію провайдера.
