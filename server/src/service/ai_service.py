from datetime import datetime
from src.util.ai_util import Ai
from src.util.ocr_util import Ocr
import json
from typing import List, Dict

class AIService:
    def __init__(self, ai_util,ocr_util):
        self.Ai = ai_util
        self.Ocr = ocr_util


    def get_patience_data(self, user_data,image,comment):
        prospect = self.Ocr.transform_to_text(image)
        json = self.Ai.get_formula(prospect, user_data, comment)
        return json

    def get_events(self, body: Dict) -> List[Dict]:
        """
        Generate a list of Google Calendar event dictionaries for a medication schedule.

        Parameters:
            body (dict): Input with keys:
                - name (str): Medication name.
                - start (dict): Contains 'dateTime' (ISO string) and 'timeZone' (str).
                - amount (int): Number of doses (events).
                - distance (int): Hours between doses.

        Returns:
            List[Dict]: A list of event dictionaries compatible with the Google Calendar API.
        """
        body = json.loads(body)

        name = body["name"]
        start_iso = body["start"]["dateTime"]
        tz = body["start"]["timeZone"]
        amount = body["amount"]
        distance = body["distance"]

        start_dt = datetime.fromisoformat(start_iso)
        events = []

        for i in range(amount):
            event_start = start_dt + datetime.timedelta(hours=i * distance)
            event_end = event_start + datetime.timedelta(hours=1)  # 1-hour duration

            events.append({
                "summary": name,
                "start": {
                    "dateTime": event_start.isoformat(),
                    "timeZone": tz
                },
                "end": {
                    "dateTime": event_end.isoformat(),
                    "timeZone": tz
                },
                "description": f"Pill #{i + 1}"
            })

        return events

if __name__ == '__main__':
    ai_util_ex = Ai(model="qwen_custom:latest")
    ocr_util_ex = Ocr('en')
    ai_service_ex = AIService(ai_util_ex, ocr_util_ex)

    patient_ex = {"sex": "female", "age_group": "child", "pregnant": "NO"}
    images = ["../../sample/image3.png", "../../sample/image2.png"]

    body = ai_service_ex.get_patience_data(user_data=patient_ex,image=images,comment="I have 10 pills, I need to take 2 in a day,I have fever")
    print(body)
    print(ai_service_ex.get_events(body))