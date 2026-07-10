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
    const imageFile = req.files?.['image']?.[0] || null;
    const prompt = req.body.prompt || '';
    const base64Image = req.body.base64Image || null;

    const hasFile = !!imageFile;
    const hasBase64 = !!base64Image;
    const hasPrompt = !!prompt.trim();

    if (!hasFile && !hasBase64 && !hasPrompt) {
      return res.status(400).json({ success: false, message: 'Provide an image (upload or base64) or a text prompt.' });
    }

    let finalBase64 = base64Image;
    let mimeType = 'image/jpeg';

    if (imageFile) {
      finalBase64 = imageFile.buffer.toString('base64');
      mimeType = imageFile.mimetype || 'image/jpeg';
    }

    const finalPrompt = prompt || 'Refine this into a photorealistic tattoo on skin, high quality, sharp focus, intricate details, professional tattoo';

    const parts = [];

    if (finalBase64) {
      parts.push({ inlineData: { data: finalBase64, mimeType } });
    }

    parts.push({ text: finalPrompt });

    const result = await ai.models.generateContent({
      model: 'gemini-3.1-flash-image',
      contents: [{ role: 'user', parts }],
    });

    const candidate = result.candidates?.[0];
    if (!candidate) {
      throw new Error('No candidates returned from Gemini');
    }

    const contentParts = candidate.content?.parts;
    if (!contentParts || contentParts.length === 0) {
      throw new Error('No content parts returned from Gemini');
    }

    let imageBuffer = null;

    for (const part of contentParts) {
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
    console.error(error);
    res.status(500).json({ success: false, message: error.message || 'An unknown error occurred during generation.' });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});