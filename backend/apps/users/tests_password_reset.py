from django.urls import reverse
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from rest_framework import status
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.contrib.auth.tokens import PasswordResetTokenGenerator

User = get_user_model()


class PasswordResetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='pr', email='pr@example.com', password='Password1', identification='99999999')

    def test_password_reset_flow(self):
        url = reverse('password_reset')
        resp = self.client.post(url, {'email': 'pr@example.com'}, format='json')
        # 204 No Content to avoid leaking
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)

        # Generate token and confirm
        token_gen = PasswordResetTokenGenerator()
        token = token_gen.make_token(self.user)
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))

        confirm_url = reverse('password_reset_confirm')
        new_pwd = 'NewPass1'
        resp2 = self.client.post(confirm_url, {'uid': uid, 'token': token, 'new_password': new_pwd, 'new_password_confirm': new_pwd}, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)

        # login with new password
        from rest_framework_simplejwt.views import TokenObtainPairView
        login_url = reverse('token_obtain_pair')
        login_resp = self.client.post(login_url, {'username': self.user.username, 'password': new_pwd}, format='json')
        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_resp.data)
