from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


class CustomUserAdmin(UserAdmin):
	list_display = ('username', 'email', 'first_name', 'last_name', 'role', 'is_active')
	list_filter = ('role', 'is_active', 'is_staff', 'is_superuser')
	fieldsets = UserAdmin.fieldsets + (
		('Información adicional', {'fields': ('role', 'phone')}),
	)
	add_fieldsets = UserAdmin.add_fieldsets + (
		('Información adicional', {'fields': ('role', 'phone')}),
	)


admin.site.register(User, CustomUserAdmin)
