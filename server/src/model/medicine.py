from dataclasses import dataclass
from datetime import datetime, time

@dataclass
class Medicine:
    name: str
    date: datetime
    time: time

    @staticmethod
    def from_dict(data: dict) -> 'Medicine':
        # expects 'time' as "HH:MM"
        hour, minute = map(int, data['time'].split(':'))
        return Medicine(
            name=data['name'],
            date=datetime.fromisoformat(data['date']),
            time=time(hour=hour, minute=minute)
        )

    def to_dict(self) -> dict:
        return {
            'name': self.name,
            'date': self.date.isoformat(),
            'time': f"{self.time.hour:02d}:{self.time.minute:02d}"
        }