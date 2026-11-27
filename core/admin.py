from django.contrib import admin

from .models import Visit


@admin.register(Visit)
class VisitAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "ip_address")
