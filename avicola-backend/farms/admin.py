from django.contrib import admin
from .models import Farm, House


@admin.register(Farm)
class FarmAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'responsible', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('name', 'location')


@admin.register(House)
class HouseAdmin(admin.ModelAdmin):
    list_display = ('name', 'farm', 'capacity', 'current_capacity', 'responsible', 'status')
    list_filter = ('status', 'farm')
    search_fields = ('name', 'farm__name')
from django.contrib import admin

# Register your models here.
