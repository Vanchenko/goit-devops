variable "ecr_name" {
  description = "Назва репозиторію ECR"
  type        = string
}

variable "scan_on_push" {
  description = "Автоматично сканувати образи на вразливості при push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "MUTABLE — тег можна перезаписати, IMMUTABLE — ні"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Допустимі значення: MUTABLE або IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Дозволити видалення репозиторію разом з образами при terraform destroy"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Скільки останніх образів зберігати в репозиторії"
  type        = number
  default     = 10
}
