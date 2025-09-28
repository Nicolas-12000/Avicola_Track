from django.test import Client
from django.contrib.auth import get_user_model

User = get_user_model()
# create a debug user
u = User.objects.create(username='dbg-run', identification='dbg-run-1')
client = Client()
client.force_login(u)
resp = client.post('/api/inventory/bulk-update-stock/', '{"updates":[{"id":1,"delta":-1}], "client_id":"c3"}', content_type='application/json')
print('STATUS', resp.status_code)
print(resp.content)
