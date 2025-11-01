import 'package:cloud_firestore/cloud_firestore.dart';

class SkillSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedData() async {
    final skills = {
      "reading": {
        "topics": {
          "animals": {
            "name": "Animals",
            "image": "https://res.cloudinary.com/demo/image/upload/animals.jpg",
            "description": "Learn about animals around the world.",
            "lessons": [
              {
                "passage":
                    "Elephants are the largest land animals on Earth. They have long trunks and big ears.",
                "questions": [
                  {
                    "question": "What is the largest land animal?",
                    "options": ["Elephant", "Lion", "Tiger", "Bear"],
                    "correctAnswer": "Elephant",
                  },
                  {
                    "question": "What do elephants have?",
                    "options": ["Long trunks", "Wings", "Fins", "Tails"],
                    "correctAnswer": "Long trunks",
                  },
                ],
              },
            ],
          },
          "school": {
            "name": "At School",
            "image": "https://res.cloudinary.com/demo/image/upload/school.jpg",
            "description": "Reading about school activities.",
            "lessons": [
              {
                "passage":
                    "Students study various subjects like Math and English.",
                "questions": [
                  {
                    "question": "Which subjects do students study?",
                    "options": ["Math", "History", "Art", "All of them"],
                    "correctAnswer": "All of them",
                  },
                ],
              },
            ],
          },
        },
      },
      "listening": {
        "topics": {
          "daily": {
            "name": "Daily Routine",
            "image": "https://res.cloudinary.com/demo/image/upload/daily.jpg",
            "description": "Listen to daily conversations.",
            "audios": [
              {
                "audioUrl":
                    "https://res.cloudinary.com/demo/video/upload/audio1.mp3",
                "transcript": "I wake up at 6 a.m. and go to school.",
                "questions": [
                  {
                    "question": "What time does the speaker wake up?",
                    "options": ["5 a.m.", "6 a.m.", "7 a.m.", "8 a.m."],
                    "correctAnswer": "6 a.m.",
                  },
                ],
              },
            ],
          },
        },
      },
      "speaking": {
        "topics": {
          "travel": {
            "name": "Travel",
            "image": "https://res.cloudinary.com/demo/image/upload/travel.jpg",
            "description": "Practice speaking about travel.",
            "prompts": [
              {
                "question": "Describe your favorite trip.",
                "tips": [
                  "Where did you go?",
                  "Who did you travel with?",
                  "What did you enjoy the most?",
                ],
              },
            ],
          },
        },
      },
      "writing": {
        "topics": {
          "environment": {
            "name": "Environment",
            "image":
                "https://res.cloudinary.com/demo/image/upload/environment.jpg",
            "description": "Write about how to protect the planet.",
            "prompts": [
              {
                "question": "How can students protect the environment?",
                "tips": [
                  "Use examples from daily life.",
                  "Include an introduction and conclusion.",
                ],
              },
            ],
          },
        },
      },
    };

    print("🌱 Seeding skills data to Firestore...");

    for (final skillEntry in skills.entries) {
      final skillName = skillEntry.key;
      final skillData = skillEntry.value;

      // Tạo document kỹ năng (reading, listening, ...)
      final skillDoc = _firestore.collection('skills').doc(skillName);
      await skillDoc.set({});

      final topics = skillData['topics'] as Map<String, dynamic>;

      for (final topicEntry in topics.entries) {
        final topicName = topicEntry.key;
        final topicData = topicEntry.value as Map<String, dynamic>;

        // Tạo topic trong subcollection topics
        final topicRef = skillDoc.collection('topics').doc(topicName);
        await topicRef.set({
          "name": topicData['name'],
          "image": topicData['image'],
          "description": topicData['description'],
        });

        // Thêm subcollection lessons/audios/prompts tùy loại kỹ năng
        if (topicData.containsKey('lessons')) {
          for (final lesson in topicData['lessons']) {
            await topicRef.collection('lessons').add(lesson);
          }
        } else if (topicData.containsKey('audios')) {
          for (final audio in topicData['audios']) {
            await topicRef.collection('audios').add(audio);
          }
        } else if (topicData.containsKey('prompts')) {
          for (final prompt in topicData['prompts']) {
            await topicRef.collection('prompts').add(prompt);
          }
        }
      }
    }

    print("✅ Seeding completed!");
  }
}
