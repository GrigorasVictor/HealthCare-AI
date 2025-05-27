import pickle

from googleapiclient.discovery import build
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
import os
from src.util.calendar_util import Calendar


class CalendarService:
    SCOPES = ['https://www.googleapis.com/auth/calendar']

    def __init__(self, util, token_path, credentials_path):
        """
        Initializes the CalendarService by authenticating with Google Calendar API.

        Parameters:
        - util: helper object responsible for credential storage and retrieval
                (must implement get_token_path(), get_credentials_path(), save_token())
        """
        self.util = util
        self.token_path = token_path
        self.credentials_path = credentials_path
        creds = None

        # Load existing credentials if available
        if os.path.exists(self.token_path):
            with open(self.token_path, 'rb') as token_file:
                creds = pickle.load(token_file)

        # If no valid credentials, initiate OAuth2 flow
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                   self.credentials_path, self.SCOPES
                )
                creds = flow.run_local_server(port=0)
            # Save credentials for future use
            with open(self.token_path, 'wb') as token_file:
                pickle.dump(creds, token_file)

        # Build the Calendar service and initialize the events resource
        service = build('calendar', 'v3', credentials=creds)
        self.google = service.events()



    def create_event(self, event_body, calendar_id='primary'):
        """
        Creates an event in Google Calendar.

        Parameters:
        - event_body: dict containing event fields, e.g.:
            {
                'summary': 'Paracetamol',
                'start': {'dateTime': '2025-05-25T12:00:00', 'timeZone': 'Europe/Bucharest'},
                'end':   {'dateTime': '2025-05-25T13:00:00', 'timeZone': 'Europe/Bucharest'},
                'description': 'Paracetamol #1'
            }
        - calendar_id: ID of the calendar to insert into (default: 'primary')

        Returns:
        - The created event resource as returned by the API
        """
        created_event = self.google.insert(
            calendarId=calendar_id,
            body=event_body
        ).execute()
        return created_event

if __name__ == '__main__':
    events = [{'summary': 'Paracetamol', 'start': {'dateTime': '2025-05-28T12:00:00', 'timeZone': 'Europe/Bucharest'}, 'end': {'dateTime': '2025-05-28T13:00:00', 'timeZone': 'Europe/Bucharest'}, 'description': 'Paracetamol #1'},
{'summary': 'Paracetamol', 'start': {'dateTime': '2025-05-28T16:00:00', 'timeZone': 'Europe/Bucharest'}, 'end': {'dateTime': '2025-05-28T17:00:00', 'timeZone': 'Europe/Bucharest'}, 'description': 'Paracetamol #2'},
{'summary': 'Paracetamol', 'start': {'dateTime': '2025-05-28T20:00:00', 'timeZone': 'Europe/Bucharest'}, 'end': {'dateTime': '2025-05-28T21:00:00', 'timeZone': 'Europe/Bucharest'}, 'description': 'Paracetamol #3'},
{'summary': 'Paracetamol', 'start': {'dateTime': '2025-05-28T00:00:00', 'timeZone': 'Europe/Bucharest'}, 'end': {'dateTime': '2025-05-28T01:00:00', 'timeZone': 'Europe/Bucharest'}, 'description': 'Paracetamol #4'}]
    token_path = "../../token.json"
    credentials_path = "../../credentials.json"
    calendar_util = Calendar
    calendar_service = CalendarService(calendar_util,token_path,credentials_path)
    for event in events:
        calendar_service.create_event(event)

