from rest_framework import permissions
from apps.farms.models import Shed


class IsAssignedShedWorkerOrFarmAdmin(permissions.BasePermission):
    """Permite acciones si el usuario es el galponero asignado del galpón o el administrador de la granja

    This permission handles both object-level checks (has_object_permission) and creation-time checks
    (has_permission for POST) where no object exists yet. For POST it expects the incoming data to
    include a `shed` id which is used to validate assignment.
    """

    def has_permission(self, request, view):
        user = request.user
        # Require authentication first
        if not user or not user.is_authenticated:
            return False

        # Staff allowed
        if user.is_staff:
            return True

        # For creation (POST) validate against the target shed
        if request.method == 'POST':
            shed_id = request.data.get('shed')
            if not shed_id:
                return False
            try:
                shed = Shed.objects.get(pk=shed_id)
            except Shed.DoesNotExist:
                return False

            role_name = getattr(getattr(user, 'role', None), 'name', None)
            if role_name == 'Galponero':
                return shed.assigned_worker == user
            if role_name == 'Administrador de Granja':
                return getattr(shed.farm, 'farm_manager', None) == user

            return False

        # For non-creation methods, allow and defer to object-level checks (if any)
        return True

    def has_object_permission(self, request, view, obj):
        # obj can be a Flock (has shed) or a Shed
        user = request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        # Staff and system admins allowed
        if user.is_staff:
            return True

        # If object is a Flock, get its shed
        shed = getattr(obj, 'shed', None) or obj

        if role_name == 'Galponero':
            return shed.assigned_worker == user

        if role_name == 'Administrador de Granja':
            return getattr(shed.farm, 'farm_manager', None) == user

        return False
