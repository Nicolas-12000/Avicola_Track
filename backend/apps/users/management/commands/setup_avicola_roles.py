from django.core.management.base import BaseCommand
from apps.users.models import Permission, Role


class Command(BaseCommand):
    help = 'Create Avicola specific roles and permissions'

    def handle(self, *args, **options):
        avicola_permissions = [
            ('view_all_farms', 'Ver todas las granjas'),
            ('create_farm', 'Crear granja'),
            ('manage_farm', 'Gestionar granja propia'),
            ('create_shed', 'Crear galpón'),
            ('assign_galponero', 'Asignar galponero'),
            ('register_daily_weight', 'Registrar peso diario'),
            ('register_mortality', 'Registrar mortalidad'),
            ('register_food_consumption', 'Registrar consumo'),
            ('manage_inventory', 'Gestionar inventario'),
            ('view_inventory', 'Ver inventario'),
            ('generate_reports', 'Generar reportes'),
            ('view_alarms', 'Ver alarmas'),
            ('resolve_conflicts', 'Resolver conflictos de sync'),
        ]

        for codename, name in avicola_permissions:
            Permission.objects.get_or_create(codename=codename, name=name)

        self._create_admin_role()
        self._create_farm_manager_role()
        self._create_veterinarian_role()
        self._create_galponero_role()

        self.stdout.write(self.style.SUCCESS('Avicola roles and permissions created/updated'))

    def _create_admin_role(self):
        role, _ = Role.objects.get_or_create(name='Administrador Sistema')
        # Admin gets all permissions
        perms = Permission.objects.all()
        role.permissions.set(perms)

    def _create_farm_manager_role(self):
        role, _ = Role.objects.get_or_create(name='Administrador de Granja')
        perm_codenames = ['view_all_farms', 'create_shed', 'assign_galponero', 'manage_farm', 'create_farm', 'approve_reports']
        perms = Permission.objects.filter(codename__in=perm_codenames)
        role.permissions.set(perms)

    def _create_veterinarian_role(self):
        role, _ = Role.objects.get_or_create(name='Veterinario')
        perm_codenames = ['register_daily_weight', 'register_mortality', 'register_food_consumption', 'generate_reports', 'view_alarms']
        perms = Permission.objects.filter(codename__in=perm_codenames)
        role.permissions.set(perms)

    def _create_galponero_role(self):
        role, _ = Role.objects.get_or_create(name='Galponero')
        galponero_permissions = [
            'register_daily_weight',
            'register_mortality',
            'register_food_consumption',
            'view_inventory',
            'view_alarms',
        ]
        perms = Permission.objects.filter(codename__in=galponero_permissions)
        role.permissions.set(perms)
