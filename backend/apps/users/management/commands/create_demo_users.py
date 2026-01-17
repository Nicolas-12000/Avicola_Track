from django.core.management.base import BaseCommand, CommandError
from apps.users.models import User, Role


class Command(BaseCommand):
    help = 'Create demo users for local testing'

    def handle(self, *args, **options):
        role_names = [
            'Administrador Sistema',
            'Administrador de Granja',
            'Veterinario',
            'Galponero',
        ]
        roles = {role.name: role for role in Role.objects.filter(name__in=role_names)}
        missing = [name for name in role_names if name not in roles]
        if missing:
            raise CommandError(
                'Faltan roles: {}. Ejecuta primero `python manage.py setup_avicola_roles`.'.format(
                    ', '.join(missing)
                )
            )

        users = [
            {
                'username': 'admin1',
                'password': 'admin1234',
                'identification': '10000001',
                'role': roles['Administrador Sistema'],
            },
            {
                'username': 'granja1',
                'password': 'granja1234',
                'identification': '10000002',
                'role': roles['Administrador de Granja'],
            },
            {
                'username': 'vet1',
                'password': 'vet1234',
                'identification': '10000003',
                'role': roles['Veterinario'],
            },
            {
                'username': 'galpon1',
                'password': 'galpon1234',
                'identification': '10000004',
                'role': roles['Galponero'],
            },
        ]

        created = 0
        updated = 0
        for data in users:
            user, was_created = User.objects.get_or_create(
                username=data['username'],
                defaults={
                    'identification': data['identification'],
                    'role': data['role'],
                },
            )
            if not was_created:
                user.identification = data['identification']
                user.role = data['role']
            user.set_password(data['password'])
            user.save()
            if was_created:
                created += 1
            else:
                updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Demo users ready. Created: {created}, Updated: {updated}.'
            )
        )
