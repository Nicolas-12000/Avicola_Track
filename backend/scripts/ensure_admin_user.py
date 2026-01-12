from django.contrib.auth import get_user_model

User = get_user_model()

username = 'admin'
password = 'admin123'
email = 'admin@example.com'

user, created = User.objects.get_or_create(username=username, defaults={
    'email': email,
    'is_active': True,
    'is_staff': True,
    'is_superuser': True,
})
if not created:
    user.is_active = True
    user.is_staff = True
    user.is_superuser = True
    user.email = email
    user.set_password(password)
    user.save()
else:
    user.set_password(password)
    user.save()

print(f"Usuario admin {'creado' if created else 'actualizado'} y activo.")
