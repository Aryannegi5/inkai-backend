const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const { GoogleGenAI } = require('@google/genai');

dotenv.config();

const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);

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

    const model = ai.models.getModel({ model: 'gemini-2.5-flash' });

    const result = await model.generateContent({
      contents: [
        {
          role: 'user',
          parts: [
            {
              inlineData: {
                data: base64Image,
                mimeType: 'image/jpeg',
              },
            },
            {
              text: prompt || 'Refine this into a photorealistic tattoo on skin, high quality, sharp focus, intricate details, professional tattoo',
            },
          ],
        },
      ],
    });

    const candidate = result.candidates?.[0];
    if (!candidate) {
      throw new Error('No candidates returned from Gemini');
    }

    const parts = candidate.content?.parts;
    if (!parts || parts.length === 0) {
      throw new Error('No content parts returned from Gemini');
    }

    let imageBuffer = null;

    for (const part of parts) {
      if (part.inlineData && part.inlineData.data) {
        imageBuffer = Buffer.from(part.inlineData.data, 'base64');
        break;
      }
    }

    if (!imageBuffer) {
      throw new Error('Gemini did not return an image in the response');
    }

    res.set('Content-Type', 'image/png');
    res.send(imageBuffer);
  } catch (error) {
    console.error('Generation error:', error.message || error);
    const message = error.message || 'Image generation failed';
    res.status(500).json({ success: false, message });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});