from django.db import models


class Visit(models.Model):
    """Запис про кожне відкриття головної сторінки — перевірка запису в PostgreSQL."""

    created_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    def __str__(self):
        return f"{self.created_at:%Y-%m-%d %H:%M:%S} {self.ip_address}"
