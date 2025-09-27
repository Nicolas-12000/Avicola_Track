from rest_framework.permissions import BasePermission


class CanAccessShed(BasePermission):
    """Verifica si el usuario puede acceder al galpón específico"""

    def has_object_permission(self, request, view, obj):
        user = request.user

        if not user or not user.is_authenticated:
            return False

        role_name = user.role.name if user.role else None

        if role_name == 'Administrador Sistema':
            return True
        if role_name == 'Administrador de Granja':
            return obj.farm.farm_manager == user
        if role_name == 'Galponero':
            return getattr(obj, 'assigned_worker', None) == user
        if role_name == 'Veterinario':
            return obj.farm in getattr(user, 'assigned_farms', []).all()

        return False
