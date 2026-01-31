from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("alarms", "0002_alter_alarmconfiguration_alarm_type"),
    ]

    operations = [
        migrations.AddField(
            model_name="alarmconfiguration",
            name="escalation_role_name",
            field=models.CharField(max_length=100, null=True, blank=True),
        ),
    ]
