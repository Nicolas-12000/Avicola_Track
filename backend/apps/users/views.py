import logging
from django.contrib.auth import get_user_model
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator

from .serializers import UserRegistrationSerializer
from .serializers import AdminUserSerializer
from .serializers import PasswordResetRequestSerializer, PasswordResetConfirmSerializer
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.core.mail import send_mail
from rest_framework import viewsets, permissions
from django.contrib.auth import get_user_model

UserModel = get_user_model()

logger = logging.getLogger(__name__)
User = get_user_model()


class RegisterAPIView(generics.CreateAPIView):
	serializer_class = UserRegistrationSerializer

	def create(self, request, *args, **kwargs):
		serializer = self.get_serializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		user = serializer.save()
		# In dev, we won't send a real email; log for audit
		logger.info(f"New user registered: {user.username} - ID: {user.identification}")
		data = {'id': user.id, 'username': user.username, 'email': user.email}
		return Response(data, status=status.HTTP_201_CREATED)


@method_decorator(ratelimit(key='ip', rate='5/m', block=True), name='post')
class CustomTokenObtainPairView(TokenObtainPairView):
	"""Extiende TokenObtainPairView para añadir info del usuario y logging."""

	def post(self, request, *args, **kwargs):
		response = super().post(request, *args, **kwargs)
		if response.status_code == 200:
			username = request.data.get('username') or request.data.get('email')
			try:
				user = User.objects.get(username=username)
			except User.DoesNotExist:
				user = None

			if user:
				logger.info(f"Login exitoso: {user.username} - IP: {request.META.get('REMOTE_ADDR')}")
				response.data['user_info'] = {
					'id': user.id,
					'role': user.role.name if user.role else None,
					'permissions': list(user.role.permissions.values_list('codename', flat=True)) if user.role else []
				}

		return response


class AdminUserViewSet(viewsets.ModelViewSet):
	queryset = UserModel.objects.all()
	serializer_class = AdminUserSerializer
	permission_classes = [permissions.IsAdminUser]



class PasswordResetRequestView(generics.GenericAPIView):
	serializer_class = PasswordResetRequestSerializer

	def post(self, request, *args, **kwargs):
		serializer = self.get_serializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		email = serializer.validated_data['email']
		try:
			user = User.objects.get(email=email)
		except User.DoesNotExist:
			# Don't reveal whether email exists
			return Response(status=status.HTTP_204_NO_CONTENT)

		token_gen = PasswordResetTokenGenerator()
		token = token_gen.make_token(user)
		uid = urlsafe_base64_encode(force_bytes(user.pk))

		# In development email prints to console (EMAIL_BACKEND default), in prod hook to real email
		reset_link = f"/auth/password-reset-confirm/?uid={uid}&token={token}"
		send_mail(
			subject='Password reset AvícolaTrack',
			message=f'Use este enlace para restablecer su contraseña: {reset_link}',
			from_email=None,
			recipient_list=[email],
			fail_silently=True,
		)
		return Response(status=status.HTTP_204_NO_CONTENT)


class PasswordResetConfirmView(generics.GenericAPIView):
	serializer_class = PasswordResetConfirmSerializer

	def post(self, request, *args, **kwargs):
		serializer = self.get_serializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		serializer.save()
		return Response(status=status.HTTP_200_OK)
