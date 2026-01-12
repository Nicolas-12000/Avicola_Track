from rest_framework.permissions import BasePermission


class IsSystemAdminOrReadOnly(BasePermission):
    """
    Solo permite crear/editar/eliminar granjas a Administrador Sistema.
    Otros roles solo pueden leer.
    """

    def has_permission(self, request, view):
        user = request.user

        if not user or not user.is_authenticated:
            return False

        # Permitir lectura a todos los usuarios autenticados
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True

        # Solo Administrador Sistema puede crear/editar/eliminar
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        return user.is_staff or role_name == 'Administrador Sistema'

    def has_object_permission(self, request, view, obj):
        user = request.user

        # Permitir lectura a todos
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True

        # Solo Administrador Sistema puede modificar/eliminar
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        return user.is_staff or role_name == 'Administrador Sistema'
