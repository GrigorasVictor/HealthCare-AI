from datetime import datetime, timedelta
from typing import List, Dict
from tzlocal import get_localzone

class Calendar:
    def __init__(self):
       self.token = None

    def convert_to_calendar_events(self, medicines: List[Dict]) -> List[Dict]:
        """
        Convert a list of medicine dictionaries to Google Calendar event dictionaries.
        Args:
            medicines: List of dictionaries with 'name', 'date', and 'time' keys
        Returns:
            List of Google Calendar event dictionaries
        """

        calendar_events = []
        for medicine in medicines:
            base_name = medicine['name'].split('#')[0].strip()
            start_dt = datetime.fromisoformat(medicine['date'])
            end_dt = start_dt + timedelta(hours=1)

            event = {
                "summary": base_name,
                "start": {
                    "dateTime": start_dt.isoformat(),
                    "timeZone": str(get_localzone()),
                },
                "end": {
                    "dateTime": end_dt.isoformat(),
                    "timeZone": str(get_localzone()),
                },
                "description": medicine['name']
            }

            calendar_events.append(event)
        return calendar_events

if __name__ == '__main__':
    calendar_util_ex = Calendar()
    medicines = [{'name': 'Paracetamol #1', 'date': '2025-05-28T12:00:00', 'time': '12:00'},
                 {'name': 'Paracetamol #2', 'date': '2025-05-28T16:00:00', 'time': '16:00'},
                 {'name': 'Paracetamol #3', 'date': '2025-05-28T20:00:00', 'time': '20:00'},
                 {'name': 'Paracetamol #4', 'date': '2025-05-28T00:00:00', 'time': '00:00'}]

    events = calendar_util_ex.convert_to_calendar_events(medicines)
    for event1 in events:
        print(event1)