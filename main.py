from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import JSONResponse
import google.generativeai as genai
import tempfile
import os

app = FastAPI()

# 🔑 Cấu hình API key Gemini
genai.configure(api_key="AIzaSyCdmsMciZoyAPvV8qxXjHfFZ9Tl0RPIwZM")

# 🧠 Model Gemini
model = genai.GenerativeModel("gemini-2.5-pro")

# ==========================
# 🎙️ 1️⃣ API chấm SPEAKING
# ==========================
@app.post("/evaluate-speaking/")
async def evaluate_speaking(audio: UploadFile = File(...)):
    try:
        # Lưu file tạm
        with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as tmp:
            tmp.write(await audio.read())
            tmp_path = tmp.name

        # Prompt hướng dẫn chấm điểm
        prompt = """
        You are an English speaking evaluator.
        Please analyze the recording and give scores (0–10) for:
        - Fluency
        - Pronunciation
        - Grammar
        - Content relevance
        Then write a short feedback paragraph.
        Respond in JSON format:
        {
          "fluency": <number>,
          "pronunciation": <number>,
          "grammar": <number>,
          "content": <number>,
          "feedback": "<string>"
        }
        """

        with open(tmp_path, "rb") as f:
            audio_data = f.read()

        response = model.generate_content([
            prompt,
            {"mime_type": "audio/mp4", "data": audio_data}
        ])

        os.remove(tmp_path)

        return JSONResponse({"evaluation": response.text})

    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)


# ==========================
# ✍️ 2️⃣ API chấm WRITING
# ==========================
@app.post("/evaluate-writing/")
async def evaluate_writing(request: Request):
    try:
        data = await request.json()
        topic_id = data.get("topicId", "")
        question = data.get("question", "")
        text = data.get("text", "")

        if not text:
            return JSONResponse({"error": "Missing 'text' field"}, status_code=400)

        prompt = f"""
        You are an English writing evaluator.
        Evaluate the following student's writing based on:
        - Grammar
        - Vocabulary
        - Coherence
        - Task Achievement

        Topic ID: {topic_id}
        Question: {question}
        Student's answer:
        {text}

        Return your response strictly in JSON format:
        {{
          "grammar": <number>,
          "vocabulary": <number>,
          "coherence": <number>,
          "taskAchievement": <number>,
          "feedback": "<short paragraph>"
        }}
        """

        response = model.generate_content(prompt)
        return JSONResponse({"evaluation": response.text})

    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)
# ==========================
# 💬 3️⃣ API ChatBox (AI Chat)
# ==========================
@app.post("/chat/")
async def chat_with_ai(request: Request):
    try:
        data = await request.json()
        user_message = data.get("message", "").strip()

        if not user_message:
            return JSONResponse({"error": "Missing 'message' field"}, status_code=400)

        prompt = f"""
        You are a friendly English tutor AI.
        The user can ask questions about English vocabulary, grammar, idioms, pronunciation, or general English topics.
        Please explain clearly, provide examples, and if applicable, give both English and Vietnamese translations.

        Example format:
        - English explanation
        - Example sentence
        - Vietnamese meaning (optional)

        User's question: {user_message}
        """

        response = model.generate_content(prompt)

        return JSONResponse({
            "reply": response.text
        })

    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)
