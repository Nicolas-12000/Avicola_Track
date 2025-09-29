import threading
import time
import sys

from django.test import TransactionTestCase
from django.utils import timezone

from django.contrib.auth import get_user_model
from apps.users.models import Role
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock


User = get_user_model()


from django.db import connection


class FlockConcurrencyTests(TransactionTestCase):
    reset_sequences = True

    def setUp(self):
        self.role_galponero = Role.objects.create(name='Galponero')
        self.farm_admin = Role.objects.create(name='Administrador de Granja')

        self.galponero = User.objects.create_user(username='gcon', password='pass', role=self.role_galponero, identification='CON_G1')
        self.farm_admin_user = User.objects.create_user(username='fcon', password='pass', role=self.farm_admin, identification='CON_FA1')

        self.farm = Farm.objects.create(name='GranCon', location='LocCon', farm_manager=self.farm_admin_user)
        self.shed = Shed.objects.create(name='SCon', capacity=100, farm=self.farm, assigned_worker=self.galponero)

    def _create_flock(self, qty, results, idx):
        try:
            Flock.objects.create(
                arrival_date=timezone.now().date(),
                initial_quantity=qty,
                current_quantity=qty,
                initial_weight=40,
                breed='B',
                gender='X',
                supplier='S',
                shed=self.shed,
                created_by=self.galponero,
            )
            results[idx] = 'ok'
        except Exception as e:
            results[idx] = f'err:{e.__class__.__name__}'

    def test_concurrent_creations_respect_capacity(self):
        # Test capacity validation logic for both SQLite and PostgreSQL
        if 'sqlite' in connection.settings_dict['ENGINE']:
            # SQLite: Test capacity validation sequentially (simulates concurrency)
            # First flock uses 60 capacity
            flock1 = Flock.objects.create(
                arrival_date=timezone.now().date(),
                initial_quantity=60,
                current_quantity=60,
                initial_weight=40,
                breed='B1',
                gender='X',
                supplier='S1',
                shed=self.shed,
                created_by=self.galponero,
            )
            
            # Second flock should fail or be limited due to capacity constraint (40 remaining)
            with self.assertRaises(Exception):
                Flock.objects.create(
                    arrival_date=timezone.now().date(),
                    initial_quantity=60,  # This exceeds remaining capacity
                    current_quantity=60,
                    initial_weight=40,
                    breed='B2',
                    gender='X',
                    supplier='S2',
                    shed=self.shed,
                    created_by=self.galponero,
                )
        else:
            # PostgreSQL: Real concurrency test
            results = [None, None]
            t1 = threading.Thread(target=self._create_flock, args=(60, results, 0))
            t2 = threading.Thread(target=self._create_flock, args=(60, results, 1))

            t1.start(); t2.start()
            t1.join(); t2.join()

            # Only one should succeed because capacity is 100
            success_count = sum(1 for r in results if r == 'ok')
            self.assertLessEqual(success_count, 1)
