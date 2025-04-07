const express = require('express');
const { MongoClient, GridFSBucket, ObjectId } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3001;

// MongoDB connection URI
const MONGO_URI = 'mongodb+srv://pendyalashivasai19:YR2VbNOfTgdblimQ@cluster0.m8rdqqe.mongodb.net/skillswap?retryWrites=true&w=majority';

MongoClient.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then((client) => {
    const db = client.db('skillswap');
    console.log('Connected to MongoDB');

    // Now register your route AFTER DB is ready
    app.get('/images/:fileId', async (req, res) => {
      try {
        const bucket = new GridFSBucket(db, { bucketName: 'profile_images' });
        const fileId = new ObjectId(req.params.fileId);

        const file = await bucket.find({ _id: fileId }).next();
        if (!file) {
          return res.status(404).send('Image not found');
        }

        res.set('Content-Type', file.contentType || 'image/jpeg');
        bucket.openDownloadStream(fileId).pipe(res);
      } catch (error) {
        console.error('Error serving image:', error);
        res.status(500).send('Error serving image');
      }
    });

    // Start server only after DB is ready
    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
    });

  })
  .catch((err) => console.error('MongoDB connection error:', err));
