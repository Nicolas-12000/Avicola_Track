"""
Mixins reutilizables para las vistas de flocks.
Elimina duplicación de lógica de filtrado por rol y perform_create.
"""


class RoleFilteredMixin:
    """Mixin que aplica filtrado de queryset basado en el rol del usuario.
    
    Uso: definir `role_flock_path` en la vista para indicar la relación al lote.
    Por defecto asume que el modelo tiene un FK directo a Flock via 'flock__shed'.
    
    Ejemplos:
        - Para modelos con FK directo a Flock: role_flock_path = 'flock__shed'
        - Para el propio Flock: role_flock_path = 'shed'
    """
    role_flock_path = 'flock__shed'  # Override en cada vista

    def apply_role_filter(self, qs):
        user = self.request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        if user.is_staff or role_name == 'Administrador Sistema':
            return qs
        if role_name == 'Administrador de Granja':
            return qs.filter(**{f'{self.role_flock_path}__farm__farm_manager': user})
        if role_name == 'Galponero':
            return qs.filter(**{f'{self.role_flock_path}__assigned_worker': user})

        return qs.none()


class RecordedByMixin:
    """Mixin que asigna recorded_by=request.user en perform_create."""

    def perform_create(self, serializer):
        serializer.save(recorded_by=self.request.user)
