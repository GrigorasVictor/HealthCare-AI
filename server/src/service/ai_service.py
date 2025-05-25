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
    ai_util = Ai(model="qwen3:8b")
    ocr_util = Ocr('en')
    ai_service = AIService(ai_util, ocr_util)
    print(ai_service.get_patience_data(user_data="",image="",comment=""))