from django.db import connection
from django.shortcuts import render

from .models import Visit


def index(request):
    # Nginx передає реальну IP клієнта в заголовку X-Real-IP.
    ip = request.META.get("HTTP_X_REAL_IP") or request.META.get("REMOTE_ADDR")
    Visit.objects.create(ip_address=ip)

    with connection.cursor() as cursor:
        cursor.execute("SELECT version()")
        db_version = cursor.fetchone()[0]

    context = {
        "db_vendor": connection.vendor,
        "db_name": connection.settings_dict["NAME"],
        "db_host": connection.settings_dict["HOST"],
        "db_version": db_version,
        "visits_total": Visit.objects.count(),
        "last_visits": Visit.objects.order_by("-created_at")[:5],
        "via_nginx": "HTTP_X_REAL_IP" in request.META,
    }
    return render(request, "core/index.html", context)
