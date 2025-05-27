from fastapi import FastAPI, Form, File, UploadFile, Depends, HTTPException
from typing import List, Dict, Any
from src.service.ai_service import AIService
from src.service.calendar_service import CalendarService
from src.util.ai_util import Ai
from src.util.calendar_util import Calendar
from src.util.ocr_util import Ocr
from dotenv import load_dotenv
import os

# Încarcă automat toate perechile CHEIE=valoare din .env
load_dotenv()

# Acum poți accesa
TOKEN_PATH       = os.getenv('TOKEN_PATH')
CREDENTIALS_PATH = os.getenv('CREDENTIALS_PATH')



server = FastAPI()

ocr_util = Ocr('en')
ai_util = Ai('qwen_custom:latest')
ai_service = AIService(ai_util, ocr_util)
calendar_util = Calendar
calendar_service = CalendarService(calendar_util,token_path=TOKEN_PATH,credentials_path=CREDENTIALS_PATH)

# Funcții de validare pentru câmpuri (toate obligatorii în afară de 'comment')
def get_gender(gender: str = Form(...)) -> str:
    if not gender:
        raise HTTPException(status_code=422, detail="'gender' is required")
    return gender


def get_child(is_child: bool = Form(...)) -> bool:
    return is_child


def get_pregnant(is_pregnant: bool = Form(...)) -> bool:
    return is_pregnant


def get_file(file: UploadFile = File(...)) -> UploadFile:
    if not file.filename:
        raise HTTPException(status_code=422, detail="'file' is required")
    return file

@server.post("/server/send", response_model=List[Dict[str, Any]])
async def send_mockup(
    comment: str = Form(None),
    gender: str = Depends(get_gender),
    child: bool = Depends(get_child),
    pregnant: bool = Depends(get_pregnant),
    file: UploadFile = Depends(get_file),
):

    user = {"gender": gender, "age_group": child, "pregnant": pregnant}
    output = ai_service.get_patience_data(user,file,comment)
    medicines = ai_service.get_medicine(output)
    calendar_events = calendar_util.convert_to_calendar_events(medicines)
    for event in calendar_events:
        calendar_service.create_event(event,calendar_id='primary')
