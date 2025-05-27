from datetime import datetime, timedelta
#from src.util.ai_util import Ai
#from src.util.ocr_util import Ocr
from typing import List, Dict
import json

from src.util.ai_util import Ai
from src.util.ocr_util import Ocr


class AIService:
    def __init__(self, ai_util,ocr_util):
        self.Ai = ai_util
        self.Ocr = ocr_util


    def get_patience_data(self, user_data,image,comment):
        prospect = self.Ocr.transform_to_text(image)
        output = json.loads(self.Ai.get_formula(prospect, user_data, comment))
        return output

    def get_medicine(self, body: Dict) -> List[Dict]:
        """
        Generate a list of Google Calendar event dictionaries for a medication schedule using the Medicine model.

        Parameters:
            body (dict): Input with keys:
                - name (str): Medication name.
                - start (dict): Contains 'dateTime' (ISO string) and 'timeZone' (str).
                - amount (int): Number of doses (events).
                - distance (int): Hours between doses.

        Returns:
            List[Dict]: A list of medicine dictionaries.
        """
        from src.model.medicine import Medicine

        events = []
        name = body.get("name")
        start_datetime_str = body.get("start", {}).get("dateTime")
        amount = body.get("amount")
        distance = body.get("distance")

        if name is None or start_datetime_str is None or amount is None or distance is None:
            return events

        start_dt = datetime.fromisoformat(start_datetime_str)
        for i in range(amount):
            event_dt = start_dt + timedelta(hours=i * distance)
            med = Medicine(
                name=f"{name} #{i + 1}",
                date=event_dt,
                time=event_dt.time()
            )
            events.append(med.to_dict())
        return events

if __name__ == '__main__':
   ai_util_ex = Ai(model="qwen_custom:latest")
   ocr_util_ex = Ocr('en')
   ai_service_ex = AIService(ai_util_ex, ocr_util_ex)

   patient_ex = {"sex": "female", "age_group": "child", "pregnant": "NO"}
   images = ["../../sample/image3.png", "../../sample/image2.png"]

   body = ai_service_ex.get_patience_data(user_data=patient_ex,image=images,comment="I have 10 pills, I need to take 2 in a day,I have fever")
   print(body)
   print(ai_service_ex.get_medicine(body))

# if __name__ == '__main__':
#     ai_util_ex = None
#     ocr_util_ex = None
#     ai_service_ex = AIService(ai_util_ex, ocr_util_ex)
#     body = {
#         "name": "Paracetamol",
#         "start": {
#             "dateTime": "2025-05-25T12:00:00",
#             "timeZone": "Europe/Bucharest"
#         },
#         "amount": 4,
#         "distance": 4
#     }
#     print(body)
#     print(ai_service_ex.get_medicine(body))