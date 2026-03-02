from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('alarms', '0005_alarm_resolution_notes_alarm_resolved_at_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='notificationlog',
            name='read_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='notificationlog',
            name='is_deleted',
            field=models.BooleanField(default=False),
        ),
    ]
