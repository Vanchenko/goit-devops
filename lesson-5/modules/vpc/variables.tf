variable "vpc_cidr_block" {
  description = "CIDR-блок VPC"
  type        = string
}

variable "public_subnets" {
  description = "CIDR-блоки публічних підмереж"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR-блоки приватних підмереж"
  type        = list(string)
}

variable "availability_zones" {
  description = "Зони доступності для підмереж (по одній на кожну публічну та приватну підмережу)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "Потрібно вказати хоча б одну зону доступності."
  }
}

variable "vpc_name" {
  description = "Назва VPC (використовується в тегах Name усіх ресурсів модуля)"
  type        = string
}
