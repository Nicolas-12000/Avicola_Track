from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()


class UserRegistrationLoginTests(APITestCase):
	def test_register_user_and_login(self):
		url = reverse('auth-register')
		data = {
			'username': 'testuser',
			'email': 'test@example.com',
			'password': 'Password1',
			'password_confirm': 'Password1',
			'identification': '12345678',
		}
		resp = self.client.post(url, data, format='json')
		self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
		self.assertIn('id', resp.data)

		# Login
		login_url = reverse('token_obtain_pair')
		login_resp = self.client.post(login_url, {'username': 'testuser', 'password': 'Password1'}, format='json')
		self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
		self.assertIn('access', login_resp.data)
		self.assertIn('refresh', login_resp.data)
