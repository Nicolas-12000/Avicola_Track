"""
Management command to hard-delete notifications that were read more than 30 days ago
or that have been soft-deleted by the user.

Run periodically via cron / Celery beat:
    python manage.py cleanup_old_notifications
"""
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.alarms.models import NotificationLog


class Command(BaseCommand):
    help = 'Delete notifications that were read > 30 days ago or soft-deleted'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Number of days after which read notifications are purged (default: 30)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']
        expiry = timezone.now() - timedelta(days=days)

        # Notifications read more than N days ago
        old_read = NotificationLog.objects.filter(read_at__isnull=False, read_at__lt=expiry)
        # Soft-deleted notifications
        soft_deleted = NotificationLog.objects.filter(is_deleted=True)

        # Combine both sets (union)
        to_delete = (old_read | soft_deleted).distinct()
        count = to_delete.count()

        if dry_run:
            self.stdout.write(self.style.WARNING(f'[DRY RUN] Would delete {count} notifications'))
        else:
            deleted, _ = to_delete.delete()
            self.stdout.write(self.style.SUCCESS(f'Deleted {deleted} old/soft-deleted notifications'))
