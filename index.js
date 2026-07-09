const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const Replicate = require('replicate');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

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

    const imageDataUri = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;

    const output = await replicate.run(
      'stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
      {
        input: {
          prompt: prompt || 'refine this tattoo design on skin, photorealistic, high quality',
          image: imageDataUri,
          prompt_strength: 0.85,
        },
      },
    );

    const imageUrl = output[0];
    const imageResponse = await fetch(imageUrl);
    const buffer = Buffer.from(await imageResponse.arrayBuffer());

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
