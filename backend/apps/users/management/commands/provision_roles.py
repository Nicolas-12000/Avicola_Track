from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Provision default roles and permissions for AvícolaTrack'

    def handle(self, *args, **options):
        from apps.users.models import Role, Permission

        defaults = {
            'Administrador Sistema': ['all_permissions'],
            'Administrador de Granja': ['view_own_farms', 'manage_sheds', 'approve_reports'],
            'Veterinario': ['view_production_records', 'register_medication', 'generate_reports'],
            'Galponero': ['register_daily_records', 'view_own_sheds', 'manage_shed_inventory'],
        }

        for role_name, perms in defaults.items():
            role, created = Role.objects.get_or_create(name=role_name)
            for p in perms:
                perm, _ = Permission.objects.get_or_create(codename=p, defaults={'name': p.replace('_', ' ').title()})
                role.permissions.add(perm)
            role.save()
            self.stdout.write(self.style.SUCCESS(f'Role provisioned: {role_name}'))

        self.stdout.write(self.style.SUCCESS('Default roles and permissions provisioned.'))
