const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

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
    const imageDataUri = `data:${mimeType};base64,${base64Image}`;

    const segmindRes = await fetch('https://api.segmind.com/v1/sdxl-img2img', {
      method: 'POST',
      headers: {
        'x-api-key': process.env.SEGMIND_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        image: imageDataUri,
        prompt: prompt || 'refine this tattoo design on skin, photorealistic, high quality, intricate details, sharp focus',
        negative_prompt: 'ugly, blurry, low quality, distorted, deformed, disfigured, bad anatomy, watermark, text',
        samples: 1,
        scheduler: 'UniPC',
        base_model: 'juggernaut',
        num_inference_steps: 30,
        guidance_scale: 6.5,
        strength: 0.65,
        seed: -1,
        base64: false,
      }),
    });

    if (!segmindRes.ok) {
      const errorText = await segmindRes.text();
      throw new Error(`Segmind API error ${segmindRes.status}: ${errorText}`);
    }

    const arrayBuffer = await segmindRes.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    res.set('Content-Type', 'image/png');
    res.send(buffer);
  } catch (error) {
    console.error('Generation error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
