from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import login
from .serializers import UserSerializer, LoginSerializer

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register(request):
	serializer = UserSerializer(data=request.data)
	if serializer.is_valid():
		user = serializer.save()
		refresh = RefreshToken.for_user(user)
		return Response({
			'user': serializer.data,
			'refresh': str(refresh),
			'access': str(refresh.access_token),
		}, status=status.HTTP_201_CREATED)
	return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
	serializer = LoginSerializer(data=request.data)
	if serializer.is_valid():
		user = serializer.validated_data['user']
		refresh = RefreshToken.for_user(user)
		return Response({
			'user': UserSerializer(user).data,
			'refresh': str(refresh),
			'access': str(refresh.access_token),
		}, status=status.HTTP_200_OK)
	return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def user_profile(request):
	serializer = UserSerializer(request.user)
	return Response(serializer.data)
