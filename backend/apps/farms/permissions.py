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

        # Solo Administrador Sistema puede crear/eliminar
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        if user.is_staff or role_name == 'Administrador Sistema':
            return True

        # Permitir a Administrador de Granja editar (PUT/PATCH) su propia granja (no crear ni eliminar)
        if role_name == 'Administrador de Granja' and request.method in ['PUT', 'PATCH']:
            # Intentar obtener el pk del objeto objetivo desde la vista
            pk = None
            try:
                pk = view.kwargs.get('pk')
            except Exception:
                pk = None

            if pk is None:
                return False

            try:
                from .models import Farm
                farm = Farm.objects.get(pk=pk)
            except Exception:
                return False

            return getattr(farm, 'farm_manager', None) == user

        return False

    def has_object_permission(self, request, view, obj):
        user = request.user

        # Permitir lectura a todos
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True

        # Administrador Sistema puede modificar/eliminar
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        if user.is_staff or role_name == 'Administrador Sistema':
            return True

        # Permitimos al Administrador de Granja modificar su propia granja (no crear/eliminar)
        # Si el objeto es una Farm y el usuario es el farm_manager, permitir edición
        try:
            from .models import Farm
        except Exception:
            Farm = None

        if Farm is not None and isinstance(obj, Farm):
            return getattr(obj, 'farm_manager', None) == user

        return False
