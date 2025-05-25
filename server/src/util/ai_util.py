import re
from datetime import date

import ollama

class Ai:
  def __init__(self, model):
    self.model = model
    self.prompt = """
You are an assistant specialized in converting a medical prescription and patient data into a strictly Google Calendar–style JSON event.
– INPUT:
  1. a complete prescription (medication names, total pill count, pills per day, dosing time window, number of days)
  2. patient data (sex, child or adult,if female – pregnant YES/NO and the country where he/she lives)
  3. optional: user comments (e.g. preferred time window)

– RULES:
1. Reply ONLY with a valid JSON object, no explanations.
2. Use exactly these keys:
   - "summary": a short description, e.g. "medication_schedule"
   - "start": object with "dateTime" (ISO 8601) and "timeZone" (e.g. "Europe/Bucharest")
   - "end": object with "dateTime" and "timeZone"
   - "recurrence": list containing a single RRULE string: FREQ=DAILY;COUNT=…
   - "medications": list of objects, each with:
       - "name" (string)
       - "totalCount" (integer)
       - "perDay" (integer)
       - "days" (integer)
       - "timeWindow" (string, e.g. "08:00-20:00")
3. If there’s a preferred time window in user comments, override the prescription’s "timeWindow".
4. Ensure every field is present and that the JSON is strictly parsable.
5. Select the suitable time zone from the country where he/she lives.

– EXAMPLE OUTPUT:
```json
{
  "summary": "medication_schedule",
  "start": {
    "dateTime": "2020-05-25T08:00:00",
    "timeZone": "Europe/Bucharest"
  },
  "end": {
    "dateTime": "2020-05-29T20:00:00",
    "timeZone": "Europe/Bucharest"
  },
  "recurrence": [
    "RRULE:FREQ=DAILY;COUNT=5"
  ],
  "medications": [
    {
      "name": "Paracetamol",
      "totalCount": 20,
      "perDay": 4,
      "days": 5,
      "timeWindow": "08:00-20:00"
    }
  ]
}"""

  def create_input(self,prescription: str, patient_info: dict, comments: str = None) -> str:
    """
    Build the full prompt including base instructions, prescription details, patient info, and optional comments.
    :param prescription: The raw prescription text.
    :param patient_info: Dictionary containing keys 'sex', 'age_group', 'pregnant' (for females), etc.
      :param comments: Optional user comments to override rules.
      :return: A combined prompt string.
      """

    patient_lines = []
    for key, value in patient_info.items():
      patient_lines.append(f"- {key}: {value}")
    patient_block = "\n".join(patient_lines)

    # Assemble all parts
    full_input = [self.prompt, "\n-- PRESCRIPTION --\n" + prescription, "\n-- PATIENT INFO --\n" + patient_block +
                  "\n-- TODAY'S DATE --\n" + date.today().strftime("%B %d, %Y")]
    if comments:
      full_input.append("\n-- COMMENTS --\n" + comments)

    return "\n".join(full_input)

  def get_event(self, prescription: str, patient_info: dict, comments: str = None) -> str:
    """
    Call the local Ollama model to generate the event JSON.
    :param prescription: Prescription text
    :param patient_info: Patient data dictionary
    :param comments: Optional comments
    :return: Parsed JSON response from the model
    """
    prompt_text = self.create_input(prescription, patient_info, comments)
    response = ollama.chat(
      model=self.model,
      messages=[
        {'role': 'user', 'content': f"{prompt_text}"},
      ])
    # remove the entire <think>...<./think> section
    summary = (re.sub(r'<think\s*>.*?</think\s*>', '', response['message']['content'], flags=re.DOTALL)
               .replace('*', '')
               .replace('```json', '')
               .replace('```', '')
               .strip())
    return summary



if __name__ == '__main__':
# Example usage:
  ai = Ai(model="qwen3:8b")
  prescription_text = """
Package Leaflet: Information for the User

Paracetamol 500 mg Tablets

Read this leaflet carefully and completely before you start taking this medicine.

1. What Paracetamol 500 mg is and what it is used for
Paracetamol 500 mg belongs to a group of medicines known as analgesics (pain relievers) and antipyretics (fever reducers). It is used to relieve mild to moderate pain and to reduce fever.

2. What you need to know before you take Paracetamol 500 mg
Do not take Paracetamol 500 mg:
- If you are allergic to paracetamol or any of the other ingredients of this medicine.

Warnings and precautions:
- Do not exceed the recommended dose.
- Consult a doctor if symptoms persist for more than 3 days.

3. How to take Paracetamol 500 mg
Always take this medicine exactly as described in this leaflet or as your doctor or pharmacist has told you.

Adults and adolescents over 15 years of age:
- The recommended dose is 1 tablet (500 mg) every 6 hours.
- Do not take more than 4 tablets (2 g) in 24 hours.
- The minimum interval between doses should be 6 hours.
- Maximum duration of treatment without medical advice is 5 days.

Method of administration:
- The tablets should be taken orally, with a sufficient amount of liquid.

4. Possible side effects
Like all medicines, this medicine can cause side effects, although not everybody gets them.

5. How to store Paracetamol 500 mg
- Store at temperatures below 25°C.
- Keep out of the sight and reach of children.

6. Contents of the pack and other information
What Paracetamol 500 mg contains:
- The active substance is paracetamol. Each tablet contains 500 mg of paracetamol.
- The other ingredients are: corn starch, povidone, stearic acid.

What Paracetamol 500 mg looks like and contents of the pack:
- Round, white tablets.
- Box containing 20 tablets.
"""
  patient = {"sex": "female", "age_group": "adult", "pregnant": "NO","country" : "Romania"}
  event = ai.get_event(prescription_text, patient, comments="Prefer morning doses 09:00-17:00")
  print(event)











