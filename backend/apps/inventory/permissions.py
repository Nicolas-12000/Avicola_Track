from rest_framework.permissions import BasePermission


class CanManageInventory(BasePermission):
    """Permission to manage inventory items based on user role and relationships."""

    def has_object_permission(self, request, view, obj):
        user = request.user

        if not user or not user.is_authenticated:
            return False

        role_name = getattr(getattr(user, 'role', None), 'name', None)

        if role_name == 'Administrador Sistema':
            return True
        if role_name == 'Administrador de Granja':
            return obj.farm.farm_manager == user
        if role_name == 'Galponero':
            if getattr(obj, 'shed', None):
                return getattr(obj.shed, 'assigned_worker', None) == user
            return user.assigned_sheds.filter(farm=obj.farm).exists()

        return False
