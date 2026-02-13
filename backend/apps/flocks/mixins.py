"""
Mixins reutilizables para las vistas.
Elimina duplicación de lógica de filtrado por rol y perform_create.
"""


class RoleFilteredMixin:
    """Mixin que aplica filtrado de queryset basado en el rol del usuario.
    
    Configuración (definir en la vista):
        role_flock_path:     ruta al galpón vía FK (ej: 'flock__shed', 'shed')
        role_farm_path:      ruta a la granja vía FK (ej: 'farm')
        role_galponero_path: ruta directa al worker (ej: 'assigned_worker')
                             Si no se define, se usa role_flock_path + '__assigned_worker'
    
    Ejemplos:
        - Modelos con FK a Flock: role_flock_path = 'flock__shed'
        - Flock model directo:    role_flock_path = 'shed'
        - Modelos con FK a Farm:  role_farm_path  = 'farm'
        - Shed model directo:     role_galponero_path = 'assigned_worker'
    """
    role_flock_path = 'flock__shed'
    role_farm_path = None
    role_galponero_path = None

    def apply_role_filter(self, qs):
        user = self.request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        if user.is_staff or role_name == 'Administrador Sistema':
            return qs

        farm_path = self.role_farm_path
        shed_path = self.role_flock_path

        if role_name == 'Administrador de Granja':
            if farm_path:
                return qs.filter(**{f'{farm_path}__farm_manager': user})
            return qs.filter(**{f'{shed_path}__farm__farm_manager': user})

        if role_name == 'Galponero':
            # Ruta directa al worker (ej: ShedViewSet con assigned_worker)
            if self.role_galponero_path:
                return qs.filter(**{self.role_galponero_path: user})
            if shed_path:
                return qs.filter(**{f'{shed_path}__assigned_worker': user})
            if farm_path:
                from apps.farms.models import Shed
                shed_ids = Shed.objects.filter(assigned_worker=user).values_list('id', flat=True)
                return qs.filter(**{f'{farm_path}__sheds__id__in': shed_ids}).distinct()
            return qs.none()

        if role_name == 'Veterinario':
            assigned_farms = getattr(user, 'assigned_farms', None)
            if assigned_farms is not None:
                if farm_path:
                    return qs.filter(**{f'{farm_path}__in': assigned_farms.all()})
                if shed_path:
                    return qs.filter(**{f'{shed_path}__farm__in': assigned_farms.all()})
            return qs.none()

        return qs.none()


class RecordedByMixin:
    """Mixin que asigna recorded_by=request.user en perform_create."""

    def perform_create(self, serializer):
        serializer.save(recorded_by=self.request.user)
