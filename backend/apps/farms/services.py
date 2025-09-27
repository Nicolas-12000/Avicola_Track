from django.core.exceptions import ValidationError
import logging

logger = logging.getLogger(__name__)


class ShedCapacityService:
    @staticmethod
    def validate_capacity(shed, new_quantity):
        """Valida si se puede agregar nueva cantidad al galpón"""
        if new_quantity <= 0:
            raise ValidationError("La cantidad debe ser mayor a 0")

        available = shed.available_capacity
        if new_quantity > available:
            raise ValidationError(
                f"Capacidad insuficiente. Disponible: {available}, "
                f"Solicitado: {new_quantity}, "
                f"Ocupación actual: {shed.current_occupancy}/{shed.capacity}"
            )

        return True

    @staticmethod
    def get_shed_utilization_report(farm):
        """Reporte de utilización de galpones de una granja"""
        sheds = farm.sheds.all()

        report = {
            'total_sheds': len(sheds),
            'total_capacity': sum(shed.capacity for shed in sheds),
            'total_occupancy': sum(shed.current_occupancy for shed in sheds),
            'sheds_detail': []
        }

        for shed in sheds:
            report['sheds_detail'].append({
                'name': shed.name,
                'capacity': shed.capacity,
                'current_occupancy': shed.current_occupancy,
                'utilization_percent': shed.occupancy_percentage,
                'galponero': shed.assigned_worker.username if shed.assigned_worker else 'Sin asignar'
            })

        return report
