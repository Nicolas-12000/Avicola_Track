"""
Utilidades compartidas para la app de usuarios.
"""
from rest_framework.exceptions import ValidationError

MIN_PASSWORD_LENGTH = 8


def validate_password_policy(password: str) -> None:
    """Valida la política de contraseña: mínimo 8 caracteres.
    
    Mantiene consistencia con el frontend (AppConstants.minPasswordLength).
    """
    if len(password) < MIN_PASSWORD_LENGTH:
        raise ValidationError(f'Contraseña debe tener mínimo {MIN_PASSWORD_LENGTH} caracteres')
