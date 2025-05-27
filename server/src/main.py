from PIL import Image
from io import BytesIO
from fastapi import FastAPI, Form, File, UploadFile, Depends, HTTPException, Response, Body,Request
from typing import List, Dict, Any

from starlette import status

from src.service.ai_service import AIService
from src.service.calendar_service import CalendarService
from src.util.ai_util import Ai
from src.util.calendar_util import Calendar
from src.util.ocr_util import Ocr
from dotenv import load_dotenv
import os
import numpy as np

load_dotenv()

TOKEN_PATH       = os.getenv('TOKEN_PATH')
CREDENTIALS_PATH = os.getenv('CREDENTIALS_PATH')

server = FastAPI()

ocr_util = Ocr('en')
ai_util = Ai('qwen_custom:latest')
ai_service = AIService(ai_util, ocr_util)
calendar_util = Calendar()
calendar_service = CalendarService(calendar_util,token_path=TOKEN_PATH,credentials_path=CREDENTIALS_PATH)

def get_gender(gender: str = Form(...)) -> str:
    if not gender:
        raise HTTPException(status_code=422, detail="'gender' is required")
    return gender

def get_child(child: bool = Form(...)) -> bool:
    return child

def get_pregnant(pregnant: bool = Form(...)) -> bool:
    return pregnant

def get_file(file: UploadFile = File(...)) -> UploadFile:
    if not file.filename:
        raise HTTPException(status_code=422, detail="'file' is required")
    return file

@server.post("/server/send", response_model=List[Dict[str, Any]])
async def send_data(
    comment: str = Form(None),
    gender: str = Depends(get_gender),
    child: bool = Depends(get_child),
    pregnant: bool = Depends(get_pregnant),
    file: UploadFile = Depends(get_file),
):
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=422, detail="Empty file")

    pil_img = Image.open(BytesIO(contents)).convert("RGB")
    img_np  = np.array(pil_img)


    user = {"gender": gender, "age_group": child, "pregnant": pregnant}
    output = ai_service.get_patience_data(user,[img_np],comment)
    medicines = ai_service.get_medicine(output)
    print(user)
    print(output)
    print(medicines)
    print(comment)
    return medicines

@server.post("/server/calendar", status_code=status.HTTP_200_OK)
async def send_calendar(request: Request):
    medicines = await request.json()
    print(medicines)
    if not isinstance(medicines, list):
        raise HTTPException(status_code=422, detail="'medicines' must be a list")

    events = calendar_util.convert_to_calendar_events(medicines)
    for evt in events:
        calendar_service.create_event(evt, calendar_id="primary")

    return Response(status_code=status.HTTP_200_OK)