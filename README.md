 Zenora: Multi-Modal Mental Health Intervention for Gen Z
"Bridging the gap between 'I'm fine' and actual emotional well-being using Digital Phenotyping."

Zenora is a specialized mental health platform built for the Indian student community. By fusing 8 distinct "digital biomarkers"—including typing dynamics, voice rants, and Hinglish-aware sentiment analysis—Zenora detects emotional distress patterns before they escalate into crises.

🚀 Key Innovations
1. Digital Phenotyping (8-Mode Fusion)
Zenora doesn't just ask "How are you?" It analyzes passive and active markers to build a holistic emotional profile:

Keystroke Dynamics: Monitoring typing speed and latency as markers for anxiety.

Voice Rant Analysis: Extracting deep sentiment from natural, spoken language.

The Vibe Slider: A frictionless, non-verbal daily check-in.

Hinglish NLP: Understanding the unique "Code-Mixed" language of Gen Z.

2. Clinical Validation
Unlike generic mood trackers, Zenora's scoring system is designed to correlate with gold-standard clinical benchmarks:

PHQ-9 (Patient Health Questionnaire for Depression)

GAD-7 (Generalized Anxiety Disorder Scale)

🛠️ Technical Architecture
Layer	Technology	Status
Backend	FastAPI (Python 3.10+)	✅ Functional
Database	Firebase (Real-time & Auth)	✅ Integrated
Frontend	React.js / Tailwind CSS	✅ Prototype
NLP Engine	Llama-3.1 8B (via Groq LPU)	✅ Functional
Fine-Tuning	QLoRA Adaptation (Unsloth)	🚧 Phase 2 (WIP)

Export to Sheets

 Project Roadmap
Phase 1: Foundation (COMPLETED)
[x] Architected FastAPI backend and Firebase data schemas.

[x] Developed 8-mode data ingestion pipeline (Vibe Slider, Voice, Keystrokes).

[x] Integrated base Llama-3.1 via Groq for initial sentiment mapping.

Phase 2: Intelligent Adaptation (CURRENT FOCUS) 🚧
[ ] Hinglish Tokenization: Fine-tuning Llama-3.1 on Romanized Hindi student logs to capture linguistic nuance (e.g., "placement stress bohot zyada hai").

[ ] Quantization: Optimizing the model using 4-bit QLoRA for deployment on edge-compatible hardware.

[ ] Dataset Curation: Cleaning and de-identifying initial survey data for training.

Phase 3: Clinical Pilot (UPCOMING)
[ ] Launch 42-day study with 250 volunteers.

[ ] Perform Pearson Correlation analysis (r) to validate AI accuracy against GAD-7 scores.

Privacy & Ethics
Privacy by Design: All PII (Personally Identifiable Information) is de-identified before processing.

Crisis Protocol: If "Level 3" distress is detected, the AI immediately triggers the Red Alert Protocol, bypassing standard chat to provide local emergency contacts and counseling cell links.

👨‍💻 Get Started
Installation
Clone the repository:

Bash

git clone https://github.com/your-username/zenora.git
cd zenora
Environment Setup:
Create a .env file with your GROQ_API_KEY and FIREBASE_CONFIG.

Run Backend:

Bash

pip install -r requirements.txt
uvicorn main:app --reload

 Contact & Contribution
Divyanshu Sharma
Computer Science & Engineering | Chandigarh University '27

LinkedIn: www.linkedin.com/in/divyanshu-sharma-46696728b

Email: ds7794092@gmail.com
