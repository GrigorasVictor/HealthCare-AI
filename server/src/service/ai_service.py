from src.util.ai_util import Ai
from src.util.ocr_util import Ocr

class AIService:
    def __init__(self, ai_util,ocr_util):
        self.Ai = ai_util
        self.Ocr = ocr_util


    def get_patience_data(self, user_data,image,comment):
        prospect = self.Ocr.transform_to_text(image)
        json = self.Ai.get_event(prospect, user_data, comment)
        return json

if __name__ == '__main__':
    ai_util_ex = Ai(model="qwen_custom:latest")
    ocr_util_ex = Ocr('en')
    ai_service_ex = AIService(ai_util_ex, ocr_util_ex)

    patient_ex = {"sex": "female", "age_group": "adult", "pregnant": "NO","country" : "Romania"}
    image_ex = "../../sample/image2.png"

    print(ai_service_ex.get_patience_data(user_data=patient_ex,image=image_ex,comment="I have 5 pills,I have fever"))