const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const { GoogleGenAI } = require('@google/genai');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Ink AI API is running!');
});

app.post('/api/generate-tattoo', upload.fields([
  { name: 'image', maxCount: 1 },
]), async (req, res) => {
  try {
    const image = req.files['image'] ? req.files['image'][0] : null;
    const prompt = req.body.prompt;

    if (!image) {
      return res.status(400).json({ success: false, message: 'image is required' });
    }

    const base64Image = image.buffer.toString('base64');
    const mimeType = image.mimetype || 'image/png';

    const chat = ai.chats.create({ model: 'gemini-2.5-flash-image' });

    const response = await chat.sendMessage({
      content: [
        { inlineData: { mimeType, data: base64Image } },
        prompt || 'Refine this into a photorealistic tattoo on skin, high quality, sharp focus, intricate details, professional tattoo',
      ],
    });

    let imageBuffer = null;

    for (const part of response.candidates[0].content.parts) {
      if (part.inlineData) {
        imageBuffer = Buffer.from(part.inlineData.data, 'base64');
        break;
      }
    }

    if (!imageBuffer) {
      throw new Error('Gemini did not return an image');
    }

    res.set('Content-Type', 'image/png');
    res.send(imageBuffer);
  } catch (error) {
    console.error('Generation error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
