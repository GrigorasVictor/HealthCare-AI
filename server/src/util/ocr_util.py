import easyocr

class Ocr:
    def __init__(self, language):
        self.language = language
        self.reader = easyocr.Reader([self.language])


    def transform_to_text(self, images):
        result = ""
        for image in images:
            text = self.reader.readtext(image)
            for (_, text, _) in text:
                result += text
        return result



if __name__ == '__main__':
    image1 = "../../sample/image1.png"
    Ocr = Ocr('en')
    result1 = Ocr.transform_to_text(image1)
    print(result1)

