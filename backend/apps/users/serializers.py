import re
from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.exceptions import ValidationError

from apps.users.models import Role

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'identification', 'phone', 'role')


class UserRegistrationSerializer(serializers.ModelSerializer):
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password_confirm', 'identification', 'phone')
        extra_kwargs = {'password': {'write_only': True}}

    def validate_identification(self, value):
        if not value.isdigit() or len(value) < 8:
            raise ValidationError("Identificación debe tener al menos 8 dígitos")
        return value

    def validate_password(self, password):
        if len(password) < 8:
            raise ValidationError("Contraseña debe tener mínimo 8 caracteres")
        if not re.search(r'[A-Z]', password):
            raise ValidationError("Debe contener al menos una mayúscula")
        if not re.search(r'[a-z]', password):
            raise ValidationError("Debe contener al menos una minúscula")
        if not re.search(r'\d', password):
            raise ValidationError("Debe contener al menos un número")
        return password

    def validate(self, data):
        if data.get('password') != data.get('password_confirm'):
            raise ValidationError("Las contraseñas no coinciden")
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm', None)
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class AdminUserSerializer(serializers.ModelSerializer):
    password_confirm = serializers.CharField(write_only=True, required=False)
    role = serializers.PrimaryKeyRelatedField(queryset=Role.objects.all(), required=False)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password', 'password_confirm', 'identification', 'phone', 'role')
        extra_kwargs = {'password': {'write_only': True}, 'role': {'required': False}}

    def validate(self, data):
        if data.get('password') and data.get('password_confirm'):
            if data.get('password') != data.get('password_confirm'):
                raise ValidationError('Las contraseñas no coinciden')
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm', None)
        password = validated_data.pop('password', None)
        role = validated_data.pop('role', None)
        user = User(**validated_data)
        if password:
            user.set_password(password)
        if role:
            user.role = role
        user.save()
        return user

    def update(self, instance, validated_data):
        validated_data.pop('password_confirm', None)
        password = validated_data.pop('password', None)
        role = validated_data.pop('role', None)
        for k, v in validated_data.items():
            setattr(instance, k, v)
        if password:
            instance.set_password(password)
        if role is not None:
            instance.role = role
        instance.save()
        return instance


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    uid = serializers.CharField()
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate(self, data):
        if data.get('new_password') != data.get('new_password_confirm'):
            raise ValidationError('Las contraseñas no coinciden')

        # password policy (same as registration)
        pwd = data.get('new_password')
        if len(pwd) < 8:
            raise ValidationError('Contraseña debe tener mínimo 8 caracteres')
        import re
        if not re.search(r'[A-Z]', pwd):
            raise ValidationError('Debe contener al menos una mayúscula')
        if not re.search(r'[a-z]', pwd):
            raise ValidationError('Debe contener al menos una minúscula')
        if not re.search(r'\d', pwd):
            raise ValidationError('Debe contener al menos un número')

        return data

    def save(self):
        from django.utils.http import urlsafe_base64_decode
        from django.contrib.auth.tokens import PasswordResetTokenGenerator
        from django.contrib.auth import get_user_model

        User = get_user_model()
        uid = self.validated_data['uid']
        token = self.validated_data['token']
        try:
            uid_decoded = urlsafe_base64_decode(uid).decode()
            user = User.objects.get(pk=uid_decoded)
        except Exception:
            raise ValidationError('UID inválido')

        token_gen = PasswordResetTokenGenerator()
        if not token_gen.check_token(user, token):
            raise ValidationError('Token inválido o expirado')

        user.set_password(self.validated_data['new_password'])
        user.save()
        return user


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer para cambio de contraseña de usuario autenticado"""
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_current_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise ValidationError('La contraseña actual es incorrecta')
        return value

    def validate(self, data):
        if data.get('new_password') != data.get('new_password_confirm'):
            raise ValidationError({'new_password_confirm': 'Las contraseñas no coinciden'})

        # password policy
        pwd = data.get('new_password')
        if len(pwd) < 8:
            raise ValidationError({'new_password': 'Contraseña debe tener mínimo 8 caracteres'})
        import re
        if not re.search(r'[A-Z]', pwd):
            raise ValidationError({'new_password': 'Debe contener al menos una mayúscula'})
        if not re.search(r'[a-z]', pwd):
            raise ValidationError({'new_password': 'Debe contener al menos una minúscula'})
        if not re.search(r'\d', pwd):
            raise ValidationError({'new_password': 'Debe contener al menos un número'})

        return data

    def save(self):
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save()
        return user
